module AddressesHelper
  # https://apidock.com/ruby/DateTime/strftime \
  def ui_in_time_zone_eastern(time_utc)
    "#{time_utc.in_time_zone('Eastern Time (US & Canada)').strftime("%l:%M %P %Z")}"
  end

  def ui_in_zone_epoch(epoch)
    Time.find_zone(@zone).at(epoch).strftime("%l:%M %P %Z")
  end

  def ui_in_zone_hour(hour)
    Time.find_zone(@zone).parse(hour).strftime("%l:%M %P %Z")
  end

  def ui_in_zone_hour_short(hour)
    Time.find_zone(@zone).parse(hour).strftime("%l:%M %P")
  end

  def as_time_in_zone(key)
    label = Address.human_attribute_name(key)
    "#{label} #{ui_in_zone_epoch(@current_conditions[key])}"
  end

  def address_locale_format(key)
    Address.human_attribute_name(key).gsub('{%}', '%%')
  end

  def as_temp(key)
    "#{with_format(key)}&deg;".html_safe
  end

  def with_format(key)
    value = @current_conditions[key] || 0.0
    address_locale_format(key) % value
  end

  def last_updated_at(address)
    epoch = address.body_hash['currentConditions']['datetimeEpoch']
    zone = address.body_hash['timezone']
    Time.find_zone(zone).at(epoch).strftime("%l:%M %P %Z")
  rescue NoMethodError => e
    "n/a"
  end

  def title_address
    "<strong>#{@address.resolved_as}</strong> As of #{ui_in_time_zone_eastern(@address.generated_at)}".html_safe
  end

  def title_current_conditions(epoch)
    "<strong>#{@address.resolved_as}</strong> As of #{ui_in_time_zone_eastern(@address.generated_at)}".html_safe
  end
end
