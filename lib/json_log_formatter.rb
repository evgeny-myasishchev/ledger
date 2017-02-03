require 'log4r'
require 'json'

class JsonLogFormatter < ::Log4r::Formatter
  def format(event)
    output = {
      time: DateTime.now, # TODO: Make sure this outputs with timezon rather than utc (+00:00)
      name: event.fullname,
      level: ::Log4r::LNAMES[event.level],
      message: event.data
    }
    output[:tracer] = event.tracer if event.tracer
    output.to_json + "\n"
  end
end
