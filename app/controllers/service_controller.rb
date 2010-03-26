require 'digest/md5'

class ServiceController < ApplicationController
  before_filter :auth
  before_filter :post_required, :except => :index

  def index
    pages = [
      { :id => 'ping', :selected => true },
      { :id => 'traceroute' },
      { :id => 'mtr' },
      { :id => 'host' },
      { :id => 'whois' },
      { :id => 'nmap' },
    ]
    @pages = pages.select { |page| page unless AppConfig.pages.disabled.include?(page[:id]) }
    @contacts_link = AppConfig.contacts.link
  end

  def ping
    host = params['host']
    
    return if !valid_form { |errors|
      validate_host(errors, 'host', host)
    }
    
    execute("ping -c 3 #{host} 2>&1")
  end
  
  def traceroute
    host = params['host']
    resolve = '-n' if params['resolve'].blank?
    
    return if !valid_form { |errors|
      validate_host(errors, 'host', host)
    }
    
    execute("traceroute #{resolve} #{host} 2>&1")
  end
  
  def mtr
    host = params['host']
    
    return if !valid_form { |errors|
      validate_host(errors, 'host', host)
    }
    
    execute("mtr -c 3 -r #{host} 2>&1")
  end
  
  def host
    host = params['host']
    server = params['server']
    verbose = '-a' if !params['verbose'].blank?
    
    return if !valid_form { |errors|
      validate_host(errors, 'host', host)
      validate_host(errors, 'server', server) if !server.blank?
    }

    execute("host #{verbose} #{host} #{server} 2>&1")
  end
  
  def whois
    host = params['host']
    
    return if !valid_form { |errors|
      validate_host(errors, 'host', host)
    }
    
    execute("whois #{host} 2>&1")
  end
  
  def nmap
    host = params['host']
    port = params['port']
    
    return if !valid_form { |errors|
      validate_host(errors, 'host', host)
      validate_range(errors, 'port', port, 1, 65535) if !port.blank?
    }
    
    port = "-p#{port}" if !port.blank?
    
    execute("nmap #{port} #{host} 2>&1")
  end
  
  private
  
    def auth
      return true if !AppConfig.auth.enabled
      authenticate_or_request_with_http_basic do |login, password| 
        login == AppConfig.auth.login && Digest::MD5.hexdigest(password) == AppConfig.auth.password
      end
    end
    
    def post_required
      redirect_to :action => 'index' and return false if request.get?
    end
    
    def execute(command)
      logger.info("Command (IP #{request.remote_ip}): #{command}")
      @output = `#{command}`
      render :json => { :status => $?.success?, :output => @output }
    end
    
    def valid_form
      errors = []
      yield errors
      render :json => { :errors => errors } and return false if !errors.empty?
      return true
    end
    
    def validate_host(errors, field_name, field)
      errors.push({ :field => field_name, :text => 'Invalid domain or IP' }) if field !~ /^[-\.a-z0-9]+$/i
    end
  
    def validate_range(errors, field_name, field, min, max)
      if field.to_i.to_s != field or field.to_i < min or field.to_i > max
        errors.push({ :field => field_name, :text => "Number should be in range [#{min}, #{max}]" })
      end
    end
  
end
