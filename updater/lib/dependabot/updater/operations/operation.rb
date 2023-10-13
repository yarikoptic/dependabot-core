# typed: true
# frozen_string_literal: true

module Dependabot
  class Updater
    module Operations
      module Operation
        extend T::Sig
        extend T::Helpers
        abstract!

        module ClassMethods
          extend T::Sig
          extend T::Helpers
          abstract!

          sig { abstract.params(job: Dependabot::Job).void }
          def applies_to?(job:); end

          sig { abstract.returns(Symbol) }
          def tag_name; end
        end

        mixes_in_class_methods(ClassMethods)
      end

      sig { abstract.returns(Dependabot::DependencyChange) }
      def perform; end
    end
  end
end
