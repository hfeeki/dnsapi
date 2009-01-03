# = Overview
#
# Macros are used by PowerDNS on Rails to apply a whole sequence of updates to a
# specific domain in the system.
#
# The following pseudo examples might help clear it up a bit
#
# Name: Change MX to Postini
# Action 1: Remove existing MX records
# Action 2: Add 4 new MX records based on template
#
# Name: Add asset hosts to Rails app
# Action 1: Add A record for static1.%ZONE%
# Action 2: Add A record for static2.%ZONE%
#
# == Implementation
#
# The #Macro model serves are a container for a number of steps (defined as
# #MacroStep), and will perform the changes on a domain as defined by each step.
#
# Steps are ordered and will be executed in that order.
#
class Macro < ActiveRecord::Base

  scope_user
  
  validates_presence_of :name
  validates_uniqueness_of :name

  has_many :macro_steps, :dependent => :destroy
  belongs_to :user

  class << self

    def record_types
      Record.record_types - ['SOA']
    end
    
  end

  # Apply the macro instance to the provided domain
  def apply_to( domain )
    macro_steps.each do |step|

      if step.action == 'create'
        macro_create( domain, step )
      elsif step.action == 'update'
        macro_change( domain, step )
      elsif step.action == 'remove'
        macro_remove( domain, step )
      else
        raise ArgumentError, "Cannot process action: #{step.action} (#{step.inspect})"
      end
    end
  end

  private

  def macro_create( domain, step )
    rr = step.build( domain )
    rr.domain = domain
    rr.save
  end

  def macro_change( domain, step )
    domain.records.find(:all, :conditions => { :type => step.record_type }).each do |record|
      next unless record.shortname == step.name

      record.content = step.content
      record.prio = step.prio if record.is_a?( MX )
      record.save
    end
  end

  # Apply the remove macro to the domain
  def macro_remove( domain, step )
    domain.records.find(:all, :conditions => { :type => step.record_type }).each do |record|
      
      # wild card or shortname match
      record.destroy if step.name == '*' || record.shortname == step.name
    end
  end
  
end

