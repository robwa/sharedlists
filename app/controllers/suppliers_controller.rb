class SuppliersController < ApplicationController

  before_filter :authenticate_supplier_admin!, :except => [:index, :new, :create]

  # GET /suppliers
  # GET /suppliers.xml
  def index
    @suppliers = Supplier.all

    respond_to do |format|
      format.html # index.rhtml
      format.xml  { render :xml => @suppliers.to_xml }
    end
  end

  # GET /suppliers/1
  # GET /suppliers/1.xml
  def show
    @supplier = Supplier.find(params[:id])

    respond_to do |format|
      format.html # show.rhtml
      format.xml  { render :xml => @supplier.to_xml }
    end
  end

  # GET /suppliers/new
  def new
    @supplier = Supplier.new
  end

  # GET /suppliers/1;edit
  def edit
    @supplier = Supplier.find(params[:id])
  end

  # POST /suppliers
  # POST /suppliers.xml
  def create
    @supplier = Supplier.new(params[:supplier])

    respond_to do |format|
      if @supplier.save
        flash[:notice] = 'Supplier was successfully created.'
        format.html { redirect_to supplier_url(@supplier) }
        format.xml  { head :created, :location => supplier_url(@supplier) }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @supplier.errors.to_xml }
      end
    end
  end

  # PUT /suppliers/1
  # PUT /suppliers/1.xml
  def update
    @supplier = Supplier.find(params[:id])
    attrs = params[:supplier]

    respond_to do |format|
      # @todo fix by generating proper hidden input in html
      attrs[:bnn_sync] ||= false
      attrs[:mail_sync] ||= false
      # don't set password to blank on saving
      attrs = attrs.reject {|k,v| k == 'bnn_password' } if attrs[:bnn_password].blank?

      if @supplier.update_attributes(attrs)
        flash[:notice] = 'Supplier was successfully updated.'
        format.html { redirect_to supplier_url(@supplier) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @supplier.errors.to_xml }
      end
    end
  end

  # DELETE /suppliers/1
  # DELETE /suppliers/1.xml
  def destroy
    @supplier = Supplier.find(params[:id])
    @supplier.destroy

    respond_to do |format|
      format.html { redirect_to suppliers_url }
      format.xml  { head :ok }
    end
  end
end
