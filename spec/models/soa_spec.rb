require File.dirname(__FILE__) + '/../spec_helper'

describe SOA, "when new" do
  fixtures :all
  
  before(:each) do
    @soa = SOA.new
  end

  it "should be invalid by default" do
    @soa.should_not be_valid
  end
  
  it "should be unique per zone" do
    @soa.zone = zones( :example_com )
    @soa.should have(1).error_on(:zone_id)
  end
  
  it "should require a primary NS" do
    @soa.should have(1).error_on(:primary_ns)
  end
  
  it "should require a contact" do
    @soa.should have(1).error_on(:contact)
  end
  
  it "should have an autogenerated serial" do
    @soa.serial.should_not be_nil
  end
  
  it "should only accept positive integers as serials" do
    @soa.serial = -2008040101
    @soa.should have(1).error_on(:serial)
    
    @soa.serial = 'ISBN123456789'
    @soa.should have(1).error_on(:serial)
    
    @soa.serial = 2008040101
    @soa.should have(:no).errors_on(:serial)
  end
  
  it "should require a refresh time" do
    @soa.should have(1).error_on(:refresh)
  end
  
  it "should only accept positive integers as refresh time" do
    @soa.refresh = -86400
    @soa.should have(1).error_on(:refresh)
    
    @soa.refresh = '12h'
    @soa.should have(1).error_on(:refresh)
    
    @soa.refresh = 2008040101
    @soa.should have(:no).errors_on(:refresh)
  end
  
  it "should require a retry time" do
    @soa.should have(1).error_on(:retry)
  end
  
  it "should only accept positive integers as retry time" do
    @soa.retry = -86400
    @soa.should have(1).error_on(:retry)
    
    @soa.retry = '15m'
    @soa.should have(1).error_on(:retry)
    
    @soa.retry = 2008040101
    @soa.should have(:no).errors_on(:retry)
  end
  
  it "should require a expiry time" do
    @soa.should have(1).error_on(:expire)
  end
  
  it "should only accept positive integers as expiry times" do
    @soa.expire = -86400
    @soa.should have(1).error_on(:expire)
    
    @soa.expire = '2w'
    @soa.should have(1).error_on(:expire)
    
    @soa.expire = 2008040101
    @soa.should have(:no).errors_on(:expire)
  end
  
  it "should require a minimum time" do
    @soa.should have(1).error_on(:minimum)
  end
  
  it "should only accept positive integers as minimum times" do
    @soa.minimum = -86400
    @soa.should have(1).error_on(:minimum)
    
    @soa.minimum = '3h'
    @soa.should have(1).error_on(:minimum)
    
    @soa.minimum = 10800
    @soa.should have(:no).errors_on(:minimum)
  end
  
  it "should not allow a minimum of more than 10800 seconds (RFC2308)" do
    @soa.minimum = 84600
    @soa.should have(1).error_on(:minimum)
  end
  
end

describe SOA, "and serial numbers" do
  fixtures :all
  
  before(:each) do
    @soa = records( :example_com_soa )
  end
  
  it "should have an easy way to update (without saving)" do
    serial = @soa.serial
    serial.should_not be_nil
    
    @soa.update_serial
    
    @soa.serial.should_not eql( serial )
    @soa.serial.should >( serial )
    
    @soa.reload
    @soa.serial.should eql( serial )
  end
  
  it "should have an easy way to update (with saving)" do
    serial = @soa.serial
    serial.should_not be_nil
    
    @soa.update_serial!
    
    @soa.serial.should_not eql( serial )
    @soa.serial.should >( serial )
    
    @soa.reload
    @soa.serial.should_not eql( serial )
  end
  
  it "should update in sequence for the same day" do
    date_segment = Time.now.strftime( "%Y%m%d" )
    
    @soa.update_serial!
    @soa.serial.to_s.should eql( date_segment + '01' )
    
    @soa.update_serial!
    @soa.serial.to_s.should eql( date_segment + '02' )
    
    @soa.update_serial!
    @soa.serial.to_s.should eql( date_segment + '03' )
  end
end