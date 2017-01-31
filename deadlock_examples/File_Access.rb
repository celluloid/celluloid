class File_Access
	include Celluloid

	def open_file (aFile, bFile)
		aFile.lock_file
	end

	def lock_file
		@f1 = File.open('Account.rb', File::RDWR|File::CREAT, 0644)
		binding.pry
		@f1.flock(File::LOCK_EX)
		@f1.close
	end
end

aFile = File_Access.new
bFile = File_Access.new

aFile.async.open_file(aFile,bFile)
aFile.open_file(bFile,aFile)
