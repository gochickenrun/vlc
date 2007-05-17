-- $Id$

--[[
VLC Lua playlist modules should define two functions:
 * probe(): returns true if we want to handle the playlist in this script
 * parse(): read the incoming data and return playlist item(s)
            The playlist is a table of playlist objects.
            A playlist object has the following members:
                .path: the item's full path / URL
                .name: the item's name in playlist (OPTIONAL)
                .title: the item's Title (OPTIONAL, meta data)
                .artist: the item's Artist (OPTIONAL, meta data)
                .genre: the item's Genre (OPTIONAL, meta data)
                .copyright: the item's Copyright (OPTIONAL, meta data)
                .album: the item's Album (OPTIONAL, meta data)
                .tracknum: the item's Tracknum (OPTIONAL, meta data)
                .description: the item's Description (OPTIONAL, meta data)
                .rating: the item's Rating (OPTIONAL, meta data)
                .date: the item's Date (OPTIONAL, meta data)
                .setting: the item's Setting (OPTIONAL, meta data)
                .url: the item's URL (OPTIONAL, meta data)
                .language: the item's Language (OPTIONAL, meta data)
                .nowplaying: the item's NowPlaying (OPTIONAL, meta data)
                .publisher: the item's Publisher (OPTIONAL, meta data)
                .encodedby: the item's EncodedBy (OPTIONAL, meta data)
                .arturl: the item's ArtURL (OPTIONAL, meta data)
                .trackid: the item's TrackID (OPTIONAL, meta data)
            Invalid playlist items will be discarded by VLC.

VLC defines a global vlc object with the following members:
 * vlc.path: the URL string (without the leading http:// or file:// element)
 * vlc.access: the access used ("http" for http://, "file" for file://, etc.)
 * vlc.peek( <int> ): return the first <int> characters from the playlist file.
 * vlc.read( <int> ): read <int> characters from the playlist file.
                      THIS FUNCTION SHOULD NOT BE USED IN peek().
 * vlc.readline(): return a new line of playlist data on each call.
                   THIS FUNCTION SHOULD NOT BE USED IN peek().
 * vlc.decode_uri( <string> ): decode %xy characters in a string.
 * vlc.resolve_xml_special_chars( <string> ): decode &abc; characters in a string.

Lua scripts are tried in alphabetical order in the luaplaylist/ directory.

Lua documentation is available on http://www.lua.org .
VLC uses Lua 5.1
All the Lua standard libraries are available.
--]]

-- Helper function to get a parameter's value in a URL
function get_url_param( url, name )
    return string.gsub( vlc.path, "^.*"..name.."=([^&]*).*$", "%1" )
end

-- Probe function.
function probe()
    return vlc.access == "http"
        and string.match( vlc.path, "youtube.com" ) 
        and (  string.match( vlc.path, "watch%?v=" )
            or string.match( vlc.path, "watch_fullscreen%?video_id=" )
            or string.match( vlc.path, "p.swf" )
            or string.match( vlc.path, "player2.swf" ) )
end

-- Parse function.
function parse()
    local p = {}
    if string.match( vlc.path, "watch%?v=" )
    then -- This is the HTML page's URL
        p[1] = { path = string.gsub( vlc.path, "^(.*)watch%?v=([^&]*).*$", "http://%1v/%2" ) }
        while true do
            -- Try to find the video's title
            line = vlc.readline()
            if not line then break end
            if string.match( line, "<meta name=\"title\"" ) then
                p[1].name = string.gsub( line, "^.*content=\"([^\"]*).*$", "%1" )
                break
            end
        end
    else -- This is the flash player's URL
        p[1] = { path = "http://www.youtube.com/get_video.php?video_id="..get_url_param( vlc.path, "video_id" ).."&t="..get_url_param( vlc.patch, "t" ) }
        if string.match( vlc.path, "title=" ) then
            p[1].name = get_url_param( vlc.path, "title" )
        end
    end
    return p
end
