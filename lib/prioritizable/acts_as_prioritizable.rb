module ActsAsPrioritizable
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def acts_as_prioritizable(prioritizable_parent = :prioritizable_parent, prioritizables = :all)
      class_variable_set :@@prioritizable_parent, prioritizable_parent
      class_variable_set :@@prioritizables, prioritizables
      attr_accessible :priority
      before_save :before_save
      after_destroy :after_destroy
      include ActsAsPrioritizable::InstanceMethods
    end
  end

  module InstanceMethods
    def map_for_select(method)
      [self.send(method), priority]
    end

    def prioritizable_parent
      if self.class.send(:class_variable_get, :@@prioritizable_parent) == 'class'
        return self.class
      else
        self.send self.class.send(:class_variable_get, :@@prioritizable_parent), true
      end
    end

    def prioritizables
      prioritizable_parent.send self.class.send(:class_variable_get, :@@prioritizables)
    end

    def set_priority
      if (priority.nil? || priority == 0 || priority.blank?)
        update_attribute(:priority, lowest_priority + 1)
      end
    end

    def before_save
      unless prioritizable_parent.nil?
        bump = (prioritizables - [self]).compact.select{|owner| owner.priority.to_i == priority.to_i}
        bump.first.update_attribute(:priority, priority.to_i+1) unless bump.empty?
      end
    end

    def after_destroy
      if(priority < lowest_priority && !prioritizable_parent.nil? rescue false)
        prioritizables.select{|p| p.priority > priority rescue false }.each{|p| p.update_attribute(:priority, p.priority-1)}
      end
    end

    def reset_all_priorities
      if(!prioritizable_parent.nil?)
        i = 0
        prioritizables.each{|p| p.update_attribute(:priority, (i+=1))}
      end
    end

    def lowest_priority
      prioritizables.map(&:priority).compact.max || 0
    end
  end
end