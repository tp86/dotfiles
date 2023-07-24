require("adblock")
require("vertical_tabs")

local select = require("select")
select.label_maker = function(s)
  return s.sort(s.reverse(s.charset("fjdksla;ghtunvirmc")))
end
local follow = require("follow")
follow.pattern_maker = follow.pattern_styles.match_label

local modes = require("modes")
local video_cmd_fmt = "prime-run mpv '%s'"
modes.add_binds("ex-follow", {
  { "m", "Hint all links and open the video behind that link externally with MPV.",
      function (w)
          w:set_mode("follow", {
              prompt = "open with MPV", selector = "uri", evaluator = "uri",
              func = function (uri)
                  assert(type(uri) == "string")
                  luakit.spawn(string.format(video_cmd_fmt, uri))
                  w:notify("Launched MPV")
              end
          })
      end },
  { "M", "Open the video on the current page externally with MPV.",
      function (w)
        local uri = string.gsub(w.view.uri or "", " ", "%%20")
        luakit.spawn(string.format(video_cmd_fmt, uri))
        w:notify("Launched MPV")
      end },
})

