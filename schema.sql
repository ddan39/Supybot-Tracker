-- MySQL dump 10.13  Distrib 5.5.54, for debian-linux-gnu (x86_64)
--
-- Host: localhost    Database: 
-- ------------------------------------------------------
-- Server version	5.5.54-0+deb8u1

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Current Database: `tracker`
--

CREATE DATABASE /*!32312 IF NOT EXISTS*/ `tracker` /*!40100 DEFAULT CHARACTER SET utf8 */;

USE `tracker`;

--
-- Table structure for table `bad_passwords`
--

DROP TABLE IF EXISTS `bad_passwords`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `bad_passwords` (
  `Password` char(32) NOT NULL,
  PRIMARY KEY (`Password`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `changelog`
--

DROP TABLE IF EXISTS `changelog`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `changelog` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `Time` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  `Message` text NOT NULL,
  `Author` varchar(30) NOT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `comments`
--

DROP TABLE IF EXISTS `comments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `comments` (
  `ID` int(10) NOT NULL AUTO_INCREMENT,
  `Page` enum('artist','collages','requests','torrents') NOT NULL,
  `PageID` int(10) NOT NULL,
  `AuthorID` int(10) NOT NULL,
  `AddedTime` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  `Body` mediumtext,
  `EditedUserID` int(10) DEFAULT NULL,
  `EditedTime` datetime DEFAULT NULL,
  PRIMARY KEY (`ID`),
  KEY `Page` (`Page`,`PageID`),
  KEY `AuthorID` (`AuthorID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `comments_edits`
--

DROP TABLE IF EXISTS `comments_edits`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `comments_edits` (
  `Page` enum('forums','artist','collages','requests','torrents') DEFAULT NULL,
  `PostID` int(10) DEFAULT NULL,
  `EditUser` int(10) DEFAULT NULL,
  `EditTime` datetime DEFAULT NULL,
  `Body` mediumtext,
  KEY `EditUser` (`EditUser`),
  KEY `PostHistory` (`Page`,`PostID`,`EditTime`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `comments_edits_tmp`
--

DROP TABLE IF EXISTS `comments_edits_tmp`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `comments_edits_tmp` (
  `Page` enum('forums','artist','collages','requests','torrents') DEFAULT NULL,
  `PostID` int(10) DEFAULT NULL,
  `EditUser` int(10) DEFAULT NULL,
  `EditTime` datetime DEFAULT NULL,
  `Body` mediumtext,
  KEY `EditUser` (`EditUser`),
  KEY `PostHistory` (`Page`,`PostID`,`EditTime`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `do_not_upload`
--

DROP TABLE IF EXISTS `do_not_upload`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `do_not_upload` (
  `ID` int(10) NOT NULL AUTO_INCREMENT,
  `Name` varchar(255) NOT NULL,
  `Comment` varchar(255) NOT NULL,
  `UserID` int(10) NOT NULL,
  `Time` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  `Sequence` mediumint(8) NOT NULL,
  PRIMARY KEY (`ID`),
  KEY `Time` (`Time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ip_bans`
--

DROP TABLE IF EXISTS `ip_bans`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ip_bans` (
  `ID` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `FromIP` int(11) unsigned NOT NULL,
  `ToIP` int(11) unsigned NOT NULL,
  `Reason` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`ID`),
  UNIQUE KEY `FromIP_2` (`FromIP`,`ToIP`),
  KEY `ToIP` (`ToIP`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `log`
--

DROP TABLE IF EXISTS `log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `log` (
  `ID` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `Message` varchar(400) NOT NULL,
  `Time` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  PRIMARY KEY (`ID`),
  KEY `Time` (`Time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `new_info_hashes`
--

DROP TABLE IF EXISTS `new_info_hashes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `new_info_hashes` (
  `TorrentID` int(11) NOT NULL,
  `InfoHash` binary(20) DEFAULT NULL,
  PRIMARY KEY (`TorrentID`),
  KEY `InfoHash` (`InfoHash`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ocelot_query_times`
--

DROP TABLE IF EXISTS `ocelot_query_times`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ocelot_query_times` (
  `buffer` enum('users','torrents','snatches','peers') NOT NULL,
  `starttime` datetime NOT NULL,
  `ocelotinstance` datetime NOT NULL,
  `querylength` int(11) NOT NULL,
  `timespent` int(11) NOT NULL,
  UNIQUE KEY `starttime` (`starttime`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `requests`
--

DROP TABLE IF EXISTS `requests`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `requests` (
  `ID` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `UserID` int(10) unsigned NOT NULL DEFAULT '0',
  `TimeAdded` datetime NOT NULL,
  `LastVote` datetime DEFAULT NULL,
  `CategoryID` int(3) NOT NULL,
  `Title` varchar(255) DEFAULT NULL,
  `Year` int(4) DEFAULT NULL,
  `Image` varchar(255) DEFAULT NULL,
  `Description` text NOT NULL,
  `ReleaseType` tinyint(2) DEFAULT NULL,
  `CatalogueNumber` varchar(50) NOT NULL,
  `BitrateList` varchar(255) DEFAULT NULL,
  `FormatList` varchar(255) DEFAULT NULL,
  `MediaList` varchar(255) DEFAULT NULL,
  `LogCue` varchar(20) DEFAULT NULL,
  `FillerID` int(10) unsigned NOT NULL DEFAULT '0',
  `TorrentID` int(10) unsigned NOT NULL DEFAULT '0',
  `TimeFilled` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  `Visible` binary(1) NOT NULL DEFAULT '1',
  `RecordLabel` varchar(80) DEFAULT NULL,
  `OCLC` varchar(55) NOT NULL DEFAULT '',
  PRIMARY KEY (`ID`),
  KEY `Userid` (`UserID`),
  KEY `Name` (`Title`),
  KEY `Filled` (`TorrentID`),
  KEY `FillerID` (`FillerID`),
  KEY `TimeAdded` (`TimeAdded`),
  KEY `Year` (`Year`),
  KEY `TimeFilled` (`TimeFilled`),
  KEY `LastVote` (`LastVote`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `requests_tags`
--

DROP TABLE IF EXISTS `requests_tags`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `requests_tags` (
  `TagID` int(10) NOT NULL DEFAULT '0',
  `RequestID` int(10) NOT NULL DEFAULT '0',
  PRIMARY KEY (`TagID`,`RequestID`),
  KEY `TagID` (`TagID`),
  KEY `RequestID` (`RequestID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `requests_votes`
--

DROP TABLE IF EXISTS `requests_votes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `requests_votes` (
  `RequestID` int(10) NOT NULL DEFAULT '0',
  `UserID` int(10) NOT NULL DEFAULT '0',
  `Bounty` bigint(20) unsigned NOT NULL,
  PRIMARY KEY (`RequestID`,`UserID`),
  KEY `RequestID` (`RequestID`),
  KEY `UserID` (`UserID`),
  KEY `Bounty` (`Bounty`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `schedule`
--

DROP TABLE IF EXISTS `schedule`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `schedule` (
  `NextHour` int(2) NOT NULL DEFAULT '0',
  `NextDay` int(2) NOT NULL DEFAULT '0',
  `NextBiWeekly` int(2) NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `torrents`
--

DROP TABLE IF EXISTS `torrents`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `torrents` (
  `ID` int(10) NOT NULL AUTO_INCREMENT,
  `UserID` int(10) DEFAULT NULL,
  `Name` varchar(300) DEFAULT NULL,
  `CategoryID` int(3) NOT NULL DEFAULT '0',
  `Scene` enum('0','1') NOT NULL DEFAULT '0',
  `info_hash` blob NOT NULL,
  `FileCount` int(6) NOT NULL,
  `FileList` mediumtext NOT NULL,
  `FilePath` varchar(255) NOT NULL DEFAULT '',
  `Size` bigint(12) NOT NULL,
  `Leechers` int(6) NOT NULL DEFAULT '0',
  `Seeders` int(6) NOT NULL DEFAULT '0',
  `last_action` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  `FreeTorrent` enum('0','1','2') NOT NULL DEFAULT '0',
  `FreeLeechType` enum('0','1','2','3') NOT NULL DEFAULT '0',
  `Time` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  `Description` text,
  `Snatched` int(10) unsigned NOT NULL DEFAULT '0',
  `balance` bigint(20) NOT NULL DEFAULT '0',
  `LastReseedRequest` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  PRIMARY KEY (`ID`),
  UNIQUE KEY `InfoHash` (`info_hash`(40)),
  KEY `UserID` (`UserID`),
  KEY `FileCount` (`FileCount`),
  KEY `Size` (`Size`),
  KEY `Seeders` (`Seeders`),
  KEY `Leechers` (`Leechers`),
  KEY `Snatched` (`Snatched`),
  KEY `last_action` (`last_action`),
  KEY `Time` (`Time`),
  KEY `FreeTorrent` (`FreeTorrent`),
  KEY `Name` (`Name`(255))
) ENGINE=InnoDB AUTO_INCREMENT=128358 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `torrents_files`
--

DROP TABLE IF EXISTS `torrents_files`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `torrents_files` (
  `TorrentID` int(10) NOT NULL,
  `File` mediumblob NOT NULL,
  PRIMARY KEY (`TorrentID`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `torrents_peerlists`
--

DROP TABLE IF EXISTS `torrents_peerlists`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `torrents_peerlists` (
  `TorrentID` int(11) NOT NULL,
  `Seeders` int(11) DEFAULT NULL,
  `Leechers` int(11) DEFAULT NULL,
  `Snatches` int(11) DEFAULT NULL,
  PRIMARY KEY (`TorrentID`),
  KEY `Stats` (`TorrentID`,`Seeders`,`Leechers`,`Snatches`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `torrents_peerlists_compare`
--

DROP TABLE IF EXISTS `torrents_peerlists_compare`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `torrents_peerlists_compare` (
  `TorrentID` int(11) NOT NULL,
  `Seeders` int(11) DEFAULT NULL,
  `Leechers` int(11) DEFAULT NULL,
  `Snatches` int(11) DEFAULT NULL,
  PRIMARY KEY (`TorrentID`),
  KEY `Stats` (`TorrentID`,`Seeders`,`Leechers`,`Snatches`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `users_freeleeches`
--

DROP TABLE IF EXISTS `users_freeleeches`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `users_freeleeches` (
  `UserID` int(10) NOT NULL,
  `TorrentID` int(10) NOT NULL,
  `Time` datetime NOT NULL,
  `Expired` tinyint(1) NOT NULL DEFAULT '0',
  `Downloaded` bigint(20) NOT NULL DEFAULT '0',
  `Uses` int(10) NOT NULL DEFAULT '1',
  PRIMARY KEY (`UserID`,`TorrentID`),
  KEY `Time` (`Time`),
  KEY `Expired_Time` (`Expired`,`Time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `users_history_ips`
--

DROP TABLE IF EXISTS `users_history_ips`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `users_history_ips` (
  `UserID` int(10) NOT NULL,
  `IP` varchar(15) NOT NULL DEFAULT '0.0.0.0',
  `StartTime` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  `EndTime` datetime DEFAULT NULL,
  PRIMARY KEY (`UserID`,`IP`,`StartTime`),
  KEY `UserID` (`UserID`),
  KEY `IP` (`IP`),
  KEY `StartTime` (`StartTime`),
  KEY `EndTime` (`EndTime`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `users_history_nicks`
--

DROP TABLE IF EXISTS `users_history_nicks`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `users_history_nicks` (
  `UserID` int(10) NOT NULL,
  `Nick` varchar(15) NOT NULL DEFAULT '0.0.0.0',
  `Time` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  PRIMARY KEY (`UserID`,`Nick`,`Time`),
  KEY `UserID` (`UserID`),
  KEY `Nick` (`Nick`),
  KEY `Time` (`Time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `users_info`
--

DROP TABLE IF EXISTS `users_info`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `users_info` (
  `UserID` int(10) unsigned NOT NULL,
  `StyleID` int(10) unsigned NOT NULL,
  `StyleURL` varchar(255) DEFAULT NULL,
  `Info` text NOT NULL,
  `Avatar` varchar(255) NOT NULL,
  `AdminComment` text NOT NULL,
  `SiteOptions` text NOT NULL,
  `ViewAvatars` enum('0','1') NOT NULL DEFAULT '1',
  `Donor` enum('0','1') NOT NULL DEFAULT '0',
  `Artist` enum('0','1') NOT NULL DEFAULT '0',
  `DownloadAlt` enum('0','1') NOT NULL DEFAULT '0',
  `Warned` datetime NOT NULL,
  `SupportFor` varchar(255) NOT NULL,
  `ShowTags` enum('0','1') NOT NULL DEFAULT '1',
  `NotifyOnQuote` enum('0','1','2') NOT NULL DEFAULT '0',
  `AuthKey` varchar(32) NOT NULL,
  `ResetKey` varchar(32) NOT NULL,
  `ResetExpires` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  `JoinDate` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  `Inviter` int(10) DEFAULT NULL,
  `BitcoinAddress` varchar(34) DEFAULT NULL,
  `WarnedTimes` int(2) NOT NULL DEFAULT '0',
  `DisableAvatar` enum('0','1') NOT NULL DEFAULT '0',
  `DisableInvites` enum('0','1') NOT NULL DEFAULT '0',
  `DisablePosting` enum('0','1') NOT NULL DEFAULT '0',
  `DisableForums` enum('0','1') NOT NULL DEFAULT '0',
  `DisableIRC` enum('0','1') DEFAULT '0',
  `DisableTagging` enum('0','1') NOT NULL DEFAULT '0',
  `DisableUpload` enum('0','1') NOT NULL DEFAULT '0',
  `DisableWiki` enum('0','1') NOT NULL DEFAULT '0',
  `DisablePM` enum('0','1') NOT NULL DEFAULT '0',
  `RatioWatchEnds` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  `RatioWatchDownload` bigint(20) unsigned NOT NULL DEFAULT '0',
  `RatioWatchTimes` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `BanDate` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  `BanReason` enum('0','1','2','3','4') NOT NULL DEFAULT '0',
  `CatchupTime` datetime DEFAULT NULL,
  `LastReadNews` int(10) NOT NULL DEFAULT '0',
  `HideCountryChanges` enum('0','1') NOT NULL DEFAULT '0',
  `RestrictedForums` varchar(150) NOT NULL DEFAULT '',
  `DisableRequests` enum('0','1') NOT NULL DEFAULT '0',
  `PermittedForums` varchar(150) NOT NULL DEFAULT '',
  `UnseededAlerts` enum('0','1') NOT NULL DEFAULT '0',
  `LastReadBlog` int(10) NOT NULL DEFAULT '0',
  `InfoTitle` varchar(255) NOT NULL,
  UNIQUE KEY `UserID` (`UserID`),
  KEY `SupportFor` (`SupportFor`),
  KEY `DisableInvites` (`DisableInvites`),
  KEY `Donor` (`Donor`),
  KEY `Warned` (`Warned`),
  KEY `JoinDate` (`JoinDate`),
  KEY `Inviter` (`Inviter`),
  KEY `RatioWatchEnds` (`RatioWatchEnds`),
  KEY `RatioWatchDownload` (`RatioWatchDownload`),
  KEY `BitcoinAddress` (`BitcoinAddress`(4)),
  KEY `AuthKey` (`AuthKey`),
  KEY `ResetKey` (`ResetKey`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `users_main`
--

DROP TABLE IF EXISTS `users_main`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `users_main` (
  `ID` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `Username` varchar(20) NOT NULL,
  `Email` varchar(255) NOT NULL,
  `PassHash` varchar(60) NOT NULL,
  `Secret` char(32) NOT NULL,
  `IRCKey` char(32) DEFAULT NULL,
  `LastLogin` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  `LastAccess` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  `IP` varchar(15) NOT NULL DEFAULT '0.0.0.0',
  `Class` tinyint(2) NOT NULL DEFAULT '5',
  `Uploaded` bigint(20) unsigned NOT NULL DEFAULT '0',
  `Downloaded` bigint(20) unsigned NOT NULL DEFAULT '0',
  `Title` text NOT NULL,
  `Enabled` enum('0','1','2') NOT NULL DEFAULT '0',
  `Paranoia` text,
  `Visible` enum('1','0') NOT NULL DEFAULT '1',
  `Invites` int(10) unsigned NOT NULL DEFAULT '0',
  `PermissionID` int(10) unsigned NOT NULL,
  `CustomPermissions` text,
  `can_leech` tinyint(4) NOT NULL DEFAULT '1',
  `torrent_pass` char(32) NOT NULL,
  `RequiredRatio` double(10,8) NOT NULL DEFAULT '0.00000000',
  `RequiredRatioWork` double(10,8) NOT NULL DEFAULT '0.00000000',
  `ipcc` varchar(2) NOT NULL DEFAULT '',
  `FLTokens` int(10) NOT NULL DEFAULT '0',
  PRIMARY KEY (`ID`),
  UNIQUE KEY `Username` (`Username`),
  KEY `Email` (`Email`),
  KEY `PassHash` (`PassHash`),
  KEY `LastAccess` (`LastAccess`),
  KEY `IP` (`IP`),
  KEY `Class` (`Class`),
  KEY `Uploaded` (`Uploaded`),
  KEY `Downloaded` (`Downloaded`),
  KEY `Enabled` (`Enabled`),
  KEY `Invites` (`Invites`),
  KEY `torrent_pass` (`torrent_pass`),
  KEY `RequiredRatio` (`RequiredRatio`),
  KEY `cc_index` (`ipcc`),
  KEY `PermissionID` (`PermissionID`)
) ENGINE=InnoDB AUTO_INCREMENT=107 DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `users_torrent_history`
--

DROP TABLE IF EXISTS `users_torrent_history`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `users_torrent_history` (
  `UserID` int(10) unsigned NOT NULL,
  `NumTorrents` int(6) unsigned NOT NULL,
  `Date` int(8) unsigned NOT NULL,
  `Time` int(11) unsigned NOT NULL DEFAULT '0',
  `LastTime` int(11) unsigned NOT NULL DEFAULT '0',
  `Finished` enum('1','0') NOT NULL DEFAULT '1',
  `Weight` bigint(20) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`UserID`,`NumTorrents`,`Date`),
  KEY `Finished` (`Finished`),
  KEY `Date` (`Date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `users_torrent_history_snatch`
--

DROP TABLE IF EXISTS `users_torrent_history_snatch`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `users_torrent_history_snatch` (
  `UserID` int(10) unsigned NOT NULL,
  `NumSnatches` int(10) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`UserID`),
  KEY `NumSnatches` (`NumSnatches`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `users_torrent_history_temp`
--

DROP TABLE IF EXISTS `users_torrent_history_temp`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `users_torrent_history_temp` (
  `UserID` int(10) unsigned NOT NULL,
  `NumTorrents` int(6) unsigned NOT NULL DEFAULT '0',
  `SumTime` bigint(20) unsigned NOT NULL DEFAULT '0',
  `SeedingAvg` int(6) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`UserID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `xbt_client_whitelist`
--

DROP TABLE IF EXISTS `xbt_client_whitelist`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `xbt_client_whitelist` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `peer_id` varchar(20) DEFAULT NULL,
  `vstring` varchar(200) DEFAULT '',
  PRIMARY KEY (`id`),
  UNIQUE KEY `peer_id` (`peer_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `xbt_files_users`
--

DROP TABLE IF EXISTS `xbt_files_users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `xbt_files_users` (
  `uid` int(11) NOT NULL,
  `active` tinyint(1) NOT NULL,
  `announced` int(11) NOT NULL,
  `completed` tinyint(1) NOT NULL DEFAULT '0',
  `downloaded` bigint(20) NOT NULL,
  `remaining` bigint(20) NOT NULL,
  `uploaded` bigint(20) NOT NULL,
  `upspeed` int(10) unsigned NOT NULL,
  `downspeed` int(10) unsigned NOT NULL,
  `corrupt` bigint(20) NOT NULL DEFAULT '0',
  `timespent` int(10) unsigned NOT NULL,
  `useragent` varchar(51) NOT NULL,
  `connectable` tinyint(4) NOT NULL DEFAULT '1',
  `peer_id` binary(20) NOT NULL DEFAULT '\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0',
  `fid` int(11) NOT NULL,
  `mtime` int(11) NOT NULL,
  `ip` varchar(15) NOT NULL DEFAULT '',
  PRIMARY KEY (`peer_id`,`fid`,`uid`),
  KEY `remaining_idx` (`remaining`),
  KEY `fid_idx` (`fid`),
  KEY `mtime_idx` (`mtime`),
  KEY `uid_active` (`uid`,`active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `xbt_snatched`
--

DROP TABLE IF EXISTS `xbt_snatched`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `xbt_snatched` (
  `uid` int(11) NOT NULL DEFAULT '0',
  `tstamp` int(11) NOT NULL,
  `fid` int(11) NOT NULL,
  `IP` varchar(15) NOT NULL,
  KEY `fid` (`fid`),
  KEY `tstamp` (`tstamp`),
  KEY `uid_tstamp` (`uid`,`tstamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2017-03-26 16:37:25
