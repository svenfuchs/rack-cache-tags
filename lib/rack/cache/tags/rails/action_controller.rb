require 'method_call_tracking'

module Rack::Cache::Tags
  module Rails
    module ActionController
      module ActMacro
        # ...
        #
        #   cache_tags :index, :show, :track => ['@article', '@articles', {'@site' => :tag_counts}]
        #
        def cache_tags(*actions)
          tracks_references(*actions)

          unless caches_page_with_references?
            alias_method_chain :caching_allowed, :skipping
          end

          # options = actions.extract_options!
          after_filter(:only => actions) { |c| c.cache_control }
        end

        # Sets up reference tracking for given actions and objects
        #
        #   tracks_references :index, :show, :track => ['@article', '@articles', {'@site' => :tag_counts}]
        #
        def tracks_references(*actions)
          unless tracks_references?
            include Rack::Cache::Tags::Rails::ActionController

            # helper_method :cached_references
            # attr_writer :cached_references
            alias_method_chain :render, :reference_tracking

            class_inheritable_accessor :track_references_to
            self.track_references_to = []

            class_inheritable_accessor :track_references_on
            self.track_references_on = []
          end

          options = actions.extract_options!
          track   = options[:track]

          self.track_references_to += track.is_a?(Array) ? track : [track]
          self.track_references_to.uniq!
          self.track_references_on = actions
        end

        def caches_page_with_references?
          method_defined? :caching_allowed_without_skipping
        end

        def tracks_references?
          method_defined? :render_without_reference_tracking
        end
      end
      
      attr_reader :reference_tracker

      def cache_control
        if perform_caching && caching_allowed
          expires_in(10.years.from_now, :public => true)
          set_cache_tags
        end
      end

      def skip_caching!
        @skip_caching = true
      end

      def skip_caching?
        @skip_caching == true
      end

      protected

        def render_with_reference_tracking(*args, &block)
          args << options = args.extract_options!
          skip_caching! if options.delete(:skip_caching) || !cacheable_action?

          setup_reference_tracking if perform_caching && caching_allowed
          render_without_reference_tracking(*args, &block)
        end

        def cacheable_action?
          action = params[:action] || ''
          self.class.track_references_on.include?(action.to_sym)
        end

        def setup_reference_tracking
          trackables = self.class.track_references_to || {}
          @reference_tracker ||= MethodCallTracking::Tracker.new
          @reference_tracker.track(self, *trackables.clone)
        end

        def set_cache_tags
          cache_tags = @reference_tracker.references.map do |reference|
            reference.first.cache_tag
          end
          response.headers[Rack::Cache::TAGS_HEADER] = cache_tags.join(',') unless cache_tags.empty?
        end

        def caching_allowed_with_skipping
          caching_allowed_without_skipping && !skip_caching?
        end

      ::ActionController::Base.send(:extend, ActMacro)
    end
  end
end