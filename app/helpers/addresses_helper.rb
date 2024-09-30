module AddressesHelper
  # https://apidock.com/ruby/DateTime/strftime \
  def ui_in_time_zone(time_utc)
    "#{time_utc.in_time_zone('Eastern Time (US & Canada)')
               .strftime("%l:%M %P")} EDT"
  end

  def address_title
    "<strong>#{@address.resolved_as}</strong> As of #{ui_in_time_zone(@address.generated_at)}".html_safe
  end
end
