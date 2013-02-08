describe "Facter" do
  it "does not clobber our language" do
    original_lang = ENV['LANG']
    require 'celluloid'
    ENV['LANG'].should == original_lang
  end
end
