return function (config)
  package.loaded[config] = nil
  require(config)
end
