class Supplier < ActiveRecord::Base
  has_many :articles, :dependent => :destroy
  has_many :user_accesses, :dependent => :destroy
  has_many :users, :through => :user_accesses

  # save lists in an array in database
  serialize :lists

  EMAIL_RE = /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i.freeze

  validates :name, :address, :phone, presence: true
  validates :bnn_host, :bnn_user, :bnn_password, :bnn_sync, presence: true, if: :bnn_sync?
  validates :mail_from, presence: true, format: { with: EMAIL_RE }, if: :mail_sync?
  validates :mail_type, inclusion: { in: ArticleImport.file_formats.keys }, presence: true, if: :mail_sync?

  scope :bnn_sync, ->{ where(bnn_sync: true) }
  scope :mail_sync, ->{ where(mail_sync: true) }

  before_create :create_salt

  def bnn_path
    Rails.root.join("supplier_assets", "bnn_files", id.to_s)
  end

  def mail_path
    Rails.root.join("supplier_assets", "mail_files", id.to_s)
  end

  # mail hash checked on receiving articles update mail
  def articles_mail_hash
    digest = Digest::SHA1.new
    digest.update self.id.to_s
    digest.update ":"
    digest.update salt
    digest.update ":mail:articles"
    Base32.encode(digest.digest[1..10])
  end

  def articles_mail_address
    return unless salt.present?
    s = "#{ENV["MAILER_PREFIX"]}#{id}.#{articles_mail_hash}@#{ENV["MAILER_DOMAIN"]}"
    s = ENV["MAILER_PREFIX"] + s if ENV["MAILER_PREFIX]"].present?
    s
  end

  def sync_bnn_files
    new_files = FtpSync::sync(self)

    unless new_files.empty?
      logger.info "New bnn files for #{name}: #{new_files.inspect}"

      new_files.each do |file|
        logger.debug "parse #{file}..."
        outlisted_counter, new_counter, updated_counter, invalid_articles =
            update_articles_from_file(File.join(bnn_path, file), type: 'bnn')
        logger.info "#{file} successfully parsed: #{new_counter} new, #{updated_counter} updated, #{outlisted_counter} outlisted, #{invalid_articles.size} invalid"
      end

      if $missing_bnn_codes
        logger.info "missing bnn-codes: #{$missing_bnn_codes.uniq.sort.join(", ")}"
      end
    end
  end

  # parses file and updates articles
  #
  # @param file [File] File to update articles from
  # @returns [Array] counters for outlisted, new and updated articles, and invalid articles
  # @note options are passed on to {ArticleImport.parse}
  def update_articles_from_file(file, **opts)

    specials = invalid_articles = Array.new
    outlisted_counter, new_counter, updated_counter = 0, 0, 0
    listed = Array.new
    upload_lists = Hash.new(0)

    ArticleImport.parse(file, **opts) do |parsed_article, status|
      parsed_article[:upload_list] = opts[:upload_list] if opts[:upload_list]
      upload_lists[parsed_article[:upload_list]] += 1 if parsed_article[:upload_list]

      article = articles.find_by_number(parsed_article[:number])
      # create new article
      if status.nil? and article.nil?
        new_article = articles.build(parsed_article)
        if new_article.valid? && new_article.save
          new_counter += 1
          listed << new_article.id
        else
          invalid_articles << new_article
        end

      # update existing article
      elsif status.nil? and article
        updated_counter += 1 if article.update_attributes(parsed_article)
        listed << article.id

      # delete outlisted article
      elsif status == :outlisted and article
        article.destroy && outlisted_counter += 1

      # remember special info for article; store data to allow article after its special
      elsif status == :special
        specials << article

      # mention parsing problems
      elsif status.is_a?(String)
        new_article = articles.build(parsed_article)
        new_article.valid?
        new_article.errors[''] = status
        invalid_articles << new_article

      end
    end

    # updates articles with special infos
    specials.each do |special|
      if article = articles.find_by_number(special[:number])
        if article.note
          article.note += " | #{special[:note]}"
        else
          article.note = special[:note]
        end
        article.save
      end
    end

    # remove unlisted articles when requested
    if opts[:outlist_unlisted] || ArticleImport.file_formats[opts[:type]]::OUTLIST
      to_delete = articles.where('id NOT IN (?)', listed) # @rails4 `.where.not()`
      outlisted_counter += to_delete.delete_all
    end

    return [outlisted_counter, new_counter, updated_counter, invalid_articles]
  end

  def articles_updated_at
    articles.order('articles.updated_on DESC').first.try(:updated_on)
  end

  private

  def create_salt
    self.salt = [Array.new(6){rand(256).chr}.join].pack("m").chomp
  end
end

# == Schema Information
#
# Table name: suppliers
#
#  id            :integer(4)      not null, primary key
#  name          :string(255)     not null
#  address       :string(255)     not null
#  phone         :string(255)     not null
#  phone2        :string(255)
#  fax           :string(255)
#  email         :string(255)
#  url           :string(255)
#  delivery_days :string(255)
#  note          :string(255)
#  created_on    :datetime
#  updated_on    :datetime
#  lists         :string(255)
#  bnn_sync      :boolean(1)      default(FALSE)
#  bnn_host      :string(255)
#  bnn_user      :string(255)
#  bnn_password  :string(255)
#
