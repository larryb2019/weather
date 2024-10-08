class AddressesController < ApplicationController
  before_action :set_address, only: %i[ show edit update destroy ]

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

  def edit
  end

  def update
    if @address.update(address_params)
      redirect_to @address
    else
      render :edit
    end
  end

  def destroy
    @address.destroy

    redirect_to root_path
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_address
    @address = Address.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def address_params
    params.require(:address).permit(:input)
  end

  # Create a new address resource
  #   call the weather service
  #   and present the results
  def on_create
    model = Address.new(address_params)
    @presenter = VisualCrossing::Presenter.on_create(model) if model.valid?
    model
  end

  # NOTE: the current_weather_data
  #   will check if the cache has expired and
  #   reload the VisualCrossing weather data
  def on_show
    @presenter = VisualCrossing::Presenter.new(@address.current_weather_data)
  end
end
