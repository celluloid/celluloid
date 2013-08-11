guard 'rspec', :cli => '--format documentation' do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^lib/(.+)\.rb$})     { |m| "spec/#{m[1]}_spec.rb" }

  {
    'actor_examples' => 'actor',
    'example_actor_class' => 'actor',
    'mailbox_examples' => ['mailbox', 'evented_mailbox'],
    'task_examples' => ['tasks/task_fiber', 'tasks/task_thread'],
  }.each do |examples, spec|
    watch("spec/support/#{examples}.rb") do
      Array(spec).map { |file| "spec/celluloid/#{file}_spec.rb" }
    end
  end

  watch('spec/spec_helper.rb')  { "spec/" }
end
