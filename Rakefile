require "rubygems"
require "hoe"

Hoe.plugin :doofus, :git

Hoe.spec "modelizer" do
  developer "John Barnette", "code@jbarnette.com"

  self.extra_rdoc_files = FileList["*.rdoc"]
  self.history_file     = "CHANGELOG.rdoc"
  self.readme_file      = "README.rdoc"
  self.testlib          = :minitest

  require_ruby_version ">= 1.9.2"
end
