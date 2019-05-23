require 'inspec'
require 'pry'
require 'libraries/cpu_info'
require 'libraries/common_logs'
require 'libraries/disk_usage'

RSpec.configure do |config|
  #
  # Add a convienent name for the example group to the RSpec lexicon. This
  # allows a user to write:
  #     describe_inspec_resource 'ohai'
  #
  # As opposed to appending a type to the declaration of the spec:
  #     describe 'ohai', type: :inspec_resource'
  #
  config.alias_example_group_to :describe_inspec_resource, type: :inspec_resource
end

shared_context 'InSpec Resources', type: :inspec_resource do
  # Using the subject or described_class does not work. With strings I think that the
  #   described class is not set. With symbols or constants it may work. When there are strings
  #   the subject value gets set to the last description. This asks for the description at the
  #   top of the entire test. If that is set correctly then the rest will work.
  let(:resource_name) { self.class.top_level_description }
  # Find the resource in the registry based on the resource_name. The resource classes
  #   stored here are not exactly instances of the Resource class (e.g. OhaiResource). They are
  #   instead wrapped with the backend transport mechanism which they will be executed against.
  let(:resource_class) { Inspec::Resource.registry[resource_name] }

  # Create an instance of the resource with the mock backend and the resource name
  def resource(*args)
    resource_class.new(backend, resource_name, *args)
  end

  # This is a no-op backend that should be overridden. Below is a helper method #environment which
  #   provides some shortcuts for hiding some of the RSpec mocking/stubbing double language.
  def backend
    double(
      <<~BACKEND
        A mocked underlying backend has not been defined. This can be done through the environment
        helper method. Which enables you to specify how the mock envrionment will behave to all requests.

            environment do
              command('which ohai').returns(stdout: '/path/to/ohai')
              command('/path/to/ohai').returns(stdout: '{ "os": "mac_os_x" }')
            end
      BACKEND
    )
  end

  # The environment helper method will define a backend method that will override the above defined method
  #   that is no-op.
  def environment(&block)
    DoubleBuilder.new(self).evaluate(&block)
  end
end

# This class serves only to create a context to enable a new domain-specific-language (DSL)
#   for defining a backend in a simple way. The DoubleBuilder is constructed with the current
#   test context which it later defines the #backend method that returns the test double that
#   is built with this DSL.
class DoubleBuilder
  def initialize(test_context)
    @test_context = test_context
  end

  def evaluate(&block)
    instance_exec(&block)

    backend_doubles = self.backend_doubles
    @test_context.define_singleton_method :backend do
      b = double('backend')
      backend_doubles.each do |backend_double|
        if backend_double.inputs?
          allow(b).to receive(backend_double.name).with(*backend_double.inputs).and_return(backend_double.outputs)
        else
          allow(b).to receive(backend_double.name).with(no_args).and_return(backend_double.outputs)
        end
      end
      b
    end
  end

  # Store all the doubling specified in the evaluation
  def backend_doubles
    @backend_doubles ||= []
  end

  # rubocop:disable Style/MethodMissingSuper,Style/MissingRespondToMissing
  def method_missing(backend_method_name, *args)
    backend_double = BackendDouble.new(backend_method_name)
    backend_double.inputs = args unless args.empty?
    backend_doubles.push backend_double
    # NOTE: The block is ignored.
    self
  end
  # rubocop:enable Style/MethodMissingSuper,Style/MissingRespondToMissing

  class InSpecResouceMash < Hashie::Mash
    disable_warnings
  end
  # Create a test double that models the hash into an object
  #   and add it to the last backend double defined.
  def returns(method_signature_as_hash)
    return_result = InSpecResouceMash.new(method_signature_as_hash)
    last_double = backend_doubles.last
    results_double_name = "#{last_double.name}_#{last_double.inputs}_RESULTS"
    last_double.outputs = @test_context.double(results_double_name, return_result)
    self
  end

  # Create a object to hold the backend doubling information
  class BackendDouble
    class NoInputsSpecifed; end

    def initialize(name)
      @name = name
      @inputs = NoInputsSpecifed
    end

    def inputs?
      inputs != NoInputsSpecifed
    end

    attr_accessor :name, :inputs, :outputs
  end
end
