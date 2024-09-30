class AddressesController < ApplicationController
  before_action :set_address, only: %i[ show ]

  # GET /addresses or /addresses.json
  def index
    @addresses = Address.order(:generated_at).all.reverse
  end

  # GET /addresses/1 or /addresses/1.json
  def show
    on_show
  end

  # GET /addresses/new
  def new
    @address = Address.new
  end

  # POST /addresses or /addresses.json
  def create
    @address = on_create

    respond_to do |format|
      if @address.save
        format.html { redirect_to @address, notice: "Address was successfully created." }
        format.json { render :show, status: :created, location: @address }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @address.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_address
    @address = Address.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def address_params
    params.require(:address).permit(:input, :generated_at, :resolved_as, :body)
  end

  # Create a new address resource
  #   call the weather service
  #   and present the results
  def on_create
    model = Address.new(address_params)
    if model.valid?
      # call our endpoint and store address info
      @service = VisualCrossing::Request.on_create(model)
      @presenter = @service.presenter
    end
    model
  end

  def on_show
    @service = VisualCrossing::Request.on_show(@address)
    @presenter = @service.presenter
  end
end
