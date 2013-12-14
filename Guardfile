guard :shell do
  watch(/.*/) { |f| `ruby ./#{f.first}` if f.first =~ /\.rb/ }
end
