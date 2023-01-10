local requires = {}
function requires.reload(pkg)
  package.loaded[pkg] = nil
  require(pkg)
end
return {
  require = requires,
}
