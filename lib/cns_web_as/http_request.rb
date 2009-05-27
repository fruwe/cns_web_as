module CnsWebAs
  class HttpRequest < CnsBase::RequestResponse::RequestSignal
    def initialize publisher, name, params
      super
    end
  end
end

=begin
$REQUEST_COUNT = 0
$REQUEST_DONE = 0

$REQUEST_COUNT += 1
CnsBase.logger.info("request to #{@request[:url]} (left #{$REQUEST_COUNT - $REQUEST_DONE})") if CnsBase.logger.info?

$REQUEST_DONE += 1
CnsBase.logger.debug("request done #{@request[:url]} (left #{$REQUEST_COUNT - $REQUEST_DONE})") if CnsBase.logger.debug?
=end