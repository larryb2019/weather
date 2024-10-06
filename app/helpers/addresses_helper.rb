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

  def xas_time_in_zone(key)
    label = Address.human_attribute_name(key)
    "#{label} #{ui_in_zone_epoch(@current_conditions[key])}"
  end

  def format_degrees(value)
    "%.1f" % value
  end

  def as_degrees(value)
    t("degrees_html", temp: format_degrees(value))
  end

  def as_precip_probability(value)
    "%.0f %%" % value
  end

  def as_temp(key)
    value = @current_conditions[key]
    t("#{key}_html", temp: format_degrees(value), scope: [:activerecord, :attributes, :address])
  end

  # key:
  #   temp_html, feels_like_html
  def as_html(key, value)
    t("#{key}_html", value: value, scope: [:activerecord, :attributes, :address])
  end

  def address_locale_format(key)
    Address.human_attribute_name(key).gsub('{%}', '%%')
  end

  # key:
  #   humidity, precip_amount, precip_probability
  def with_format(key, value)
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
