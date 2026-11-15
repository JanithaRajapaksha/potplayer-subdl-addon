/*
    SubDL Subtitle Search Extension for Daum PotPlayer
    Version: 1.0
    Description: Integrates SubDL (https://subdl.com) official API for searching,
                 ranking, downloading, and auto-loading subtitles in PotPlayer.
*/

//------------------------------------------------------------------------------------------------
// Global Configuration
//------------------------------------------------------------------------------------------------
string UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36";
string API_BASE  = "https://api.subdl.com/api/v1/subtitles";
string DL_BASE   = "https://dl.subdl.com";
string api_key   = "";

//------------------------------------------------------------------------------------------------
// Extension Metadata Hooks
//------------------------------------------------------------------------------------------------
string GetTitle()
{
    return "SubDL";
}

string GetVersion()
{
    return "1.0";
}

string GetDesc()
{
    return "https://subdl.com/";
}

//------------------------------------------------------------------------------------------------
// Language Table
//------------------------------------------------------------------------------------------------
array<array<string>> LangTable = 
{
    { "EN", "English" },
    { "AR", "Arabic" },
    { "ES", "Spanish" },
    { "FR", "French" },
    { "DE", "German" },
    { "IT", "Italian" },
    { "PT", "Portuguese" },
    { "BR_PT", "Brazilian Portuguese" },
    { "RU", "Russian" },
    { "TR", "Turkish" },
    { "ID", "Indonesian" },
    { "VI", "Vietnamese" },
    { "FA", "Farsi/Persian" },
    { "HI", "Hindi" },
    { "BN", "Bengali" },
    { "ZH", "Chinese" },
    { "JA", "Japanese" },
    { "KO", "Korean" },
    { "NL", "Dutch" },
    { "PL", "Polish" },
    { "SV", "Swedish" },
    { "NO", "Norwegian" },
    { "DA", "Danish" },
    { "FI", "Finnish" },
    { "EL", "Greek" },
    { "HE", "Hebrew" },
    { "CS", "Czech" },
    { "HU", "Hungarian" },
    { "RO", "Romanian" },
    { "SK", "Slovak" },
    { "SL", "Slovenian" },
    { "HR", "Croatian" },
    { "SR", "Serbian" },
    { "BG", "Bulgarian" },
    { "UK", "Ukrainian" },
    { "TH", "Thai" },
    { "MS", "Malay" },
    { "SQ", "Albanian" },
    { "UR", "Urdu" },
    { "TA", "Tamil" },
    { "TE", "Telugu" },
    { "ML", "Malayalam" },
    { "SI", "Sinhala" }
};

string GetLanguages()
{
    string ret = "";
    for (int i = 0, len = LangTable.size(); i < len; i++)
    {
        if (ret.empty()) ret = LangTable[i][0];
        else ret = ret + "," + LangTable[i][0];
    }
    return ret;
}

//------------------------------------------------------------------------------------------------
// Lifecycle & Authentication Hooks
//------------------------------------------------------------------------------------------------
void OnInitialize()
{
    api_key = HostLoadString("subdl_api_key", "").Trim();
}

void OnFinalize()
{
}

string GetLoginTitle()
{
    return "SubDL Account Configuration";
}

string GetLoginDesc()
{
    return "Enter your SubDL API Key from https://subdl.com/panel";
}

string GetUserText()
{
    return "API Key:";
}

string GetPasswordText()
{
    return "";
}

string ServerLogin(string User, string Pass)
{
    string key = User.Trim();
    if (key.empty())
    {
        api_key = "";
        HostSaveString("subdl_api_key", "");
        return "API key cannot be empty";
    }

    api_key = key;
    HostSaveString("subdl_api_key", api_key);
    return "200 ok";
}

string ServerCheck(string User, string Pass)
{
    return ServerLogin(User, Pass);
}

void ServerLogout()
{
    api_key = "";
    HostSaveString("subdl_api_key", "");
}

//------------------------------------------------------------------------------------------------
// Path & Filename Helpers
//------------------------------------------------------------------------------------------------
string ExtractFileName(string path)
{
    int pos = path.rfind("\\");
    if (pos >= 0) path = path.substr(pos + 1);

    pos = path.rfind("/");
    if (pos >= 0) path = path.substr(pos + 1);

    return path;
}

string StripExtension(string fileName)
{
    int dotPos = fileName.rfind(".");
    if (dotPos > 0)
    {
        string ext = fileName.substr(dotPos).MakeLower();
        if (ext == ".mkv" || ext == ".mp4" || ext == ".avi" || ext == ".ts" ||
            ext == ".m2ts" || ext == ".mov" || ext == ".wmv" || ext == ".flv" ||
            ext == ".webm" || ext == ".vob" || ext == ".m4v" || ext == ".iso")
        {
            return fileName.substr(0, dotPos);
        }
    }
    return fileName;
}

//------------------------------------------------------------------------------------------------
// Release Metadata Parser
//------------------------------------------------------------------------------------------------
void ParseMedia(string fullPath, dictionary &in meta, string &out cleanTitle, string &out rawName, int &out year, int &out season, int &out episode, bool &out isTV)
{
    rawName = StripExtension(ExtractFileName(fullPath));
    year = 0;
    season = 0;
    episode = 0;
    isTV = false;

    // Check if PotPlayer metadata dictionary already has fields
    if (meta.exists("seasonNumber"))
    {
        string sStr = string(meta["seasonNumber"]);
        if (!sStr.empty())
        {
            season = parseInt(sStr);
            isTV = true;
        }
    }
    if (meta.exists("episodeNumber"))
    {
        string eStr = string(meta["episodeNumber"]);
        if (!eStr.empty())
        {
            episode = parseInt(eStr);
            isTV = true;
        }
    }
    if (meta.exists("year"))
    {
        string yStr = string(meta["year"]);
        if (!yStr.empty()) year = parseInt(yStr);
    }

    // Detect TV pattern: S##E## or ##x##
    string sMatch = HostRegExpParse(rawName, "[sS]([0-9]{1,2})[eE][0-9]{1,2}");
    string eMatch = HostRegExpParse(rawName, "[sS][0-9]{1,2}[eE]([0-9]{1,2})");
    if (sMatch.empty())
    {
        sMatch = HostRegExpParse(rawName, "(?:^|[^0-9])([0-9]{1,2})x[0-9]{1,2}");
        eMatch = HostRegExpParse(rawName, "(?:^|[^0-9])[0-9]{1,2}x([0-9]{1,2})");
    }

    if (!sMatch.empty() && !eMatch.empty())
    {
        if (season == 0) season = parseInt(sMatch);
        if (episode == 0) episode = parseInt(eMatch);
        isTV = true;
    }

    // Detect 4-digit Year (1920 - 2099)
    string yMatch = HostRegExpParse(rawName, "(?:^|[^0-9])(19[2-9][0-9]|20[0-3][0-9])(?:[^0-9]|$)");
    if (!yMatch.empty() && year == 0)
    {
        year = parseInt(yMatch);
    }

    // Extract Title portion
    string titleCandidate = "";

    if (isTV)
    {
        string beforeSE = HostRegExpParse(rawName, "^(.*?)[sS][0-9]{1,2}[eE][0-9]{1,2}");
        if (beforeSE.empty())
            beforeSE = HostRegExpParse(rawName, "^(.*?[^0-9])[0-9]{1,2}x[0-9]{1,2}");
        if (!beforeSE.empty())
            titleCandidate = beforeSE;
    }
    else if (year > 0)
    {
        string beforeYear = HostRegExpParse(rawName, "^(.*?)(?:19[2-9][0-9]|20[0-3][0-9])");
        if (!beforeYear.empty())
            titleCandidate = beforeYear;
    }

    if (titleCandidate.empty())
    {
        if (meta.exists("title") && !string(meta["title"]).empty())
            titleCandidate = string(meta["title"]);
        else
            titleCandidate = rawName;
    }

    // Normalize Title
    titleCandidate.replace(".", " ");
    titleCandidate.replace("_", " ");
    titleCandidate.replace("-", " ");
    titleCandidate.replace("(", " ");
    titleCandidate.replace(")", " ");
    titleCandidate.replace("[", " ");
    titleCandidate.replace("]", " ");

    cleanTitle = titleCandidate.Trim();
}

//------------------------------------------------------------------------------------------------
// Match Scoring Helper (0 - 100)
//------------------------------------------------------------------------------------------------
int ComputeMatchScore(string rawFileName, string releaseName)
{
    string f1 = rawFileName.MakeLower();
    string f2 = releaseName.MakeLower();

    if (f1.empty() || f2.empty()) return 0;
    if (f1 == f2) return 100;

    int score = 40;

    array<string> tags = {
        "bluray", "bdrip", "brrip", "web-dl", "webrip", "hdrip", "hdtv",
        "2160p", "1080p", "720p", "480p",
        "x264", "x265", "hevc", "avc", "10bit",
        "dts", "atmos", "ac3", "aac",
        "sparks", "rarbg", "yify", "yts", "geckos", "amiable", "flame", "surcode"
    };

    for (int i = 0, count = tags.size(); i < count; i++)
    {
        string tag = tags[i];
        bool inF1 = (f1.find(tag) >= 0);
        bool inF2 = (f2.find(tag) >= 0);

        if (inF1 && inF2) score += 10;
        else if (inF1 != inF2) score -= 2;
    }

    if (score > 98) score = 98;
    if (score < 10) score = 10;
    return score;
}

//------------------------------------------------------------------------------------------------
// Core: Subtitle Search Implementation
//------------------------------------------------------------------------------------------------
array<dictionary> SubtitleSearch(string MovieFileName, dictionary MovieMetaData)
{
    array<dictionary> results;

    // Load API Key
    if (api_key.empty())
    {
        api_key = HostLoadString("subdl_api_key", "").Trim();
    }

    if (api_key.empty())
    {
        HostMessageBox("SubDL API Key is not configured!\n\nPlease configure your key:\n1. Open PotPlayer Preferences (F5)\n2. Navigate to: Extensions -> Subtitle Search\n3. Select 'SubDL' and click 'Account / Configure'\n4. Enter your free API key from https://subdl.com/panel", "SubDL Subtitle Add-on", 0, 0);

        dictionary errItem;
        errItem["id"] = "NEED_API_KEY";
        errItem["title"] = ">> [SubDL] API Key Required! Click for instructions";
        errItem["fileName"] = "Configure SubDL API Key in Preferences (F5)";
        errItem["format"] = "srt";
        errItem["lang"] = "EN";
        errItem["language"] = "English";
        results.insertLast(errItem);
        return results;
    }

    // Parse movie / show information
    string cleanTitle;
    string rawName;
    int year = 0;
    int season = 0;
    int episode = 0;
    bool isTV = false;

    ParseMedia(MovieFileName, MovieMetaData, cleanTitle, rawName, year, season, episode, isTV);

    // Build Search URL
    string url = API_BASE + "?api_key=" + HostUrlEncode(api_key);
    url = url + "&film_name=" + HostUrlEncode(cleanTitle);

    if (isTV)
    {
        url = url + "&type=tv";
        if (season > 0)
            url = url + "&season_number=" + formatInt(season);
        if (episode > 0)
            url = url + "&episode_number=" + formatInt(episode);
    }
    else
    {
        url = url + "&type=movie";
        if (year > 0)
            url = url + "&year=" + formatInt(year);
    }

    // Enable server-side archive unpacking for direct SRT URLs
    url = url + "&unpack=1";

    // Query SubDL API
    string json = HostUrlGetString(url, UserAgent);
    JsonReader reader;
    JsonValue root;

    // Check for API unauthorized / error response
    if (reader.parse(json, root) && root.isObject())
    {
        if (root["status"].isBool() && !root["status"].asBool())
        {
            string errMsg = root["message"].isString() ? root["message"].asString() : "Unauthorized or Invalid API Key";
            HostMessageBox("SubDL API Error: " + errMsg + "\n\nPlease verify your API key in PotPlayer Preferences (F5).", "SubDL Subtitle Add-on", 3, 0);

            dictionary errItem;
            errItem["id"] = "NEED_API_KEY";
            errItem["title"] = ">> [SubDL Error] " + errMsg + " (Check F5 Preferences)";
            errItem["fileName"] = "SubDL API Error: " + errMsg;
            errItem["format"] = "srt";
            errItem["lang"] = "EN";
            errItem["language"] = "English";
            results.insertLast(errItem);
            return results;
        }
    }

    // Fallback: If no results with strict filters, try relaxed title search
    if (!root.isObject() || !root["subtitles"].isArray() || root["subtitles"].size() == 0)
    {
        string fallbackUrl = API_BASE + "?api_key=" + HostUrlEncode(api_key) + "&film_name=" + HostUrlEncode(cleanTitle) + "&unpack=1";
        json = HostUrlGetString(fallbackUrl, UserAgent);
        reader.parse(json, root);
    }

    if (root.isObject() && root["status"].isBool() && root["status"].asBool())
    {
        JsonValue subtitles = root["subtitles"];
        if (subtitles.isArray())
        {
            for (int i = 0, subCount = subtitles.size(); i < subCount; i++)
            {
                JsonValue sub = subtitles[i];
                if (!sub.isObject()) continue;

                string releaseName = sub["release_name"].isString() ? sub["release_name"].asString() : "";
                string subName     = sub["name"].isString() ? sub["name"].asString() : releaseName;
                string langCode    = sub["language"].isString() ? sub["language"].asString() : "EN";
                string langName    = sub["lang"].isString() ? sub["lang"].asString() : langCode;
                bool isHI          = (sub["hi"].isInt() && sub["hi"].asInt() == 1);

                int matchScore = ComputeMatchScore(rawName, releaseName);

                // Option 1: Unpacked individual subtitle files (direct SRT URLs)
                JsonValue unpackFiles = sub["unpack_files"];
                if (unpackFiles.isArray() && unpackFiles.size() > 0)
                {
                    for (int k = 0, fCount = unpackFiles.size(); k < fCount; k++)
                    {
                        JsonValue uFile = unpackFiles[k];
                        if (!uFile.isObject()) continue;

                        string fileUrl  = uFile["url"].isString() ? uFile["url"].asString() : "";
                        string fileName = uFile["name"].isString() ? uFile["name"].asString() : subName;

                        if (fileUrl.empty()) continue;

                        dictionary item;
                        item["id"] = fileUrl;

                        string displayTitle = releaseName;
                        if (displayTitle.empty()) displayTitle = fileName;
                        if (matchScore >= 80) displayTitle = "[Match " + formatInt(matchScore) + "%] " + displayTitle;

                        item["title"] = displayTitle;
                        item["fileName"] = fileName;
                        item["lang"] = langCode.MakeUpper();
                        item["language"] = langName;
                        item["format"] = "srt";
                        if (isHI) item["hearingImpaired"] = "1";

                        results.insertLast(item);
                    }
                }
                else
                {
                    // Option 2: Direct subtitle archive URL
                    string dlUrl = sub["url"].isString() ? sub["url"].asString() : "";
                    if (!dlUrl.empty())
                    {
                        dictionary item;
                        item["id"] = dlUrl;

                        string displayTitle = releaseName;
                        if (displayTitle.empty()) displayTitle = subName;
                        if (matchScore >= 80) displayTitle = "[Match " + formatInt(matchScore) + "%] " + displayTitle;

                        item["title"] = displayTitle;
                        item["fileName"] = releaseName;
                        item["lang"] = langCode.MakeUpper();
                        item["language"] = langName;
                        item["format"] = "srt";
                        if (isHI) item["hearingImpaired"] = "1";

                        results.insertLast(item);
                    }
                }
            }
        }
    }

    return results;
}

//------------------------------------------------------------------------------------------------
// Core: Subtitle Download Implementation
//------------------------------------------------------------------------------------------------
string SubtitleDownload(string id)
{
    if (id.empty()) return "";

    // Instruction subtitle if user clicked missing key prompt
    if (id == "NEED_API_KEY")
    {
        return "1\r\n00:00:01,000 --> 00:00:20,000\r\n{\\an8}[SubDL Subtitle Add-on]\r\nPlease enter your SubDL API Key:\r\n1. Open PotPlayer Preferences (F5)\r\n2. Go to: Extensions -> Subtitle Search\r\n3. Select 'SubDL' and click 'Account / Configure'\r\n4. Paste your free key from https://subdl.com/panel\r\n";
    }

    string downloadUrl = id;

    // Prepend CDN domain if path is relative
    if (downloadUrl.find("http://") != 0 && downloadUrl.find("https://") != 0)
    {
        if (downloadUrl.substr(0, 1) != "/")
            downloadUrl = DL_BASE + "/" + downloadUrl;
        else
            downloadUrl = DL_BASE + downloadUrl;
    }

    // Append API key if not already present
    if (downloadUrl.find("api_key=") < 0 && !api_key.empty())
    {
        if (downloadUrl.find("?") >= 0)
            downloadUrl = downloadUrl + "&api_key=" + HostUrlEncode(api_key);
        else
            downloadUrl = downloadUrl + "?api_key=" + HostUrlEncode(api_key);
    }

    // Download content
    string content = HostUrlGetString(downloadUrl, UserAgent);

    // If payload is ZIP compressed (Magic bytes: 'PK'), decompress it
    if (content.length() >= 2 && content.substr(0, 2) == "PK")
    {
        string unzipped = HostDecompress(content);
        if (!unzipped.empty()) return unzipped;
    }

    return content;
}

//------------------------------------------------------------------------------------------------
// Upload Stub
//------------------------------------------------------------------------------------------------
string GetUploadFormat()
{
    return "srt";
}

string SubtitleUpload(string MovieFileName, dictionary MovieMetaData, string SubtitleName, string SubtitleContent)
{
    return "Upload not supported";
}
