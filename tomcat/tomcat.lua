--- Common libraries provided by VersionFox (optional)
local http = require("http")
local html = require("html")

--- The following two parameters are injected by VersionFox at runtime
--- Operating system type at runtime (Windows, Linux, Darwin)
------  Default global variable
-----  OS_TYPE:  windows, linux, darwin
-----  ARCH_TYPE: 386, amd64, arm, arm64  ...
OS_TYPE = ""
--- Operating system architecture at runtime (amd64, arm64, etc.)
ARCH_TYPE = ""

TOMCAT_DIRECTORY_URL = "https://archive.apache.org/dist/tomcat/"
----- The upgrade path splice rule for tomcat is: [TOMCAT_DIRECTORY_URL]+'version/'+'v'+'package-version/'+'src'+filename
----- for this rule:
---'version' means like 'tomcat10' or 'tomcat9' and so on.
---‘package-version’ means like 'v11.0.0-M1',a specific version info.
---'filename' means the specific file name. e.x. 'apache-tomcat-11.0.0-M1-src.tar.gz'.
---the suffix usually depends on the operating system.
TOMCAT_DOWNLOAD_URL="https://archive.apache.org/dist/tomcat/%s/%s/bin/apache-tomcat-%s"


PLUGIN = {
    --- Plugin name, only numbers, letters, and underscores are allowed
    name = "tomcat",
    --- Plugin author
    author = "XuZheCheung",
    --- Plugin version
    version = "0.0.1",
    -- Update URL
    updateUrl = "https://raw.githubusercontent.com/version-fox/version-fox-plugins/main/tomcat/tomcat.lua",
}

--- Return information about the specified version based on ctx.version, including version, download URL, etc.
--- @param ctx table
--- @field ctx.version string User-input version
--- @return table Version information
function PLUGIN:PreInstall(ctx)
    local sha_suffix = ".sha512"
    local v = ctx.version
    local current_verion = string.sub(v, 1, 4)
    local osType=getOsTypeAndArch()
    local suffix=".zip"
    if osType=="mac" then
        suffix=".tar.gz"
    end
    local current_version_download_url=TOMCAT_DOWNLOAD_URL:format("tomcat-"..current_verion,v,string.sub(v,1),suffix)
    return {
        --- Version number
        version = major,
        --- Download URL, support tar.gz tar.xz zip three formats
        url = current_version_download_url,
        --- You just choose one of the checksum algorithms.
        --- sha512 checksum [optional]
        sha512 = current_version_download_url..sha_suffix,
    }
end
--- Return all available versions provided by this plugin
--- @param ctx table Empty table used as context, for future extension
--- @return table Descriptions of available versions and accompanying tool descriptions
function PLUGIN:Available(ctx)
    return parseVersion()
end
function parseVersion()
    local resp, err = http.get({
        url = TOMCAT_DIRECTORY_URL
    })
    if err ~= nil or resp.status_code ~= 200 then
        error("paring release info failed." .. err)
    end
    local result = {}
    html.parse(resp.body):find("a"):each(function(i, selection)
        local href = selection:attr("href")
        local packageName = string.sub(href, 1, -2)
        local pack_resp, err = http.get({
            url = TOMCAT_DIRECTORY_URL .. packageName
        })
        if err ~= nil or pack_resp.status_code ~= 200 then
            error("paring release info failed." .. err)
        end
        html.parse(pack_resp.body):find("a"):each(function(j, selection_current_version)
            local href_current_version = selection_current_version:attr("href")
            local current_version_package_name=sting.sub(href_current_version,1,2)
            table.insert(result,{
                version=current_version_package_name,
                note="",
            })
        end)
    end)
    return result
end

function getOsTypeAndArch()
    local osType = OS_TYPE
    local archType = ARCH_TYPE
    if OS_TYPE == "darwin" then
        osType = "mac"
    end
    if ARCH_TYPE == "amd64" then
        archType = "x64"
    elseif ARCH_TYPE == "arm64" then
        archType = "aarch64"
    elseif ARCH_TYPE == "386" then
        archType = "x32"
    end
    return {
        osType = osType, archType = archType
    }
end
--- Each SDK may have different environment variable configurations.
--- This allows plugins to define custom environment variables (including PATH settings)
--- Note: Be sure to distinguish between environment variable settings for different platforms!
--- @param ctx table Context information
--- @field ctx.version_path string SDK installation directory
function PLUGIN:EnvKeys(ctx)
    local mainPath = ctx.version_path
    return {
        {
            key = "JAVA_HOME",
            value = mainPath
        },
        {
            key = "PATH",
            value = mainPath .. "/bin"
        }
    }
end
