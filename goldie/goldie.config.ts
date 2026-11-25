// shortcut: screens were captured by hand on a real phone (no argent flows), so `goldie capture` won't work; re-add flows to automate it.
const APP_ROOT = "/home/hiteshsuthar/projects/looper_player";
const APK = `${APP_ROOT}/build/app/outputs/flutter-apk/app-play-release.apk`;
const en = (text: string) => ({ "en-US": text });

const shot = (id: string, headline: string, subhead: string) => ({
  kind: "screenshot" as const,
  id,
  flow: `store-${id}`,
  headline: en(headline),
  subhead: en(subhead),
});

export default {
  appRoot: APP_ROOT,
  appPath: APK,
  bundleId: "com.looper.player",
  android: { appPath: APK, applicationId: "com.looper.player" },
  devices: ["pixel-10-pro"],
  locales: ["en-US"],
  appearance: "dark",
  frame: { variant: "17-pro-silver" },
  theme: {
    background: "linear-gradient(165deg, #55680A 0%, #1F2608 38%, #0A0B07 100%)",
    headlineColor: "#FFFFFF",
    subheadColor: "#B9BDAE",
    fontFamily: "DM Sans",
    copyHeightRatio: 0.24,
    deviceWidthRatio: 0.84,
    template: ["classic", "offset", "tilt", "classic", "hero"],
    layout: "classic",
  },
  store: {
    name: "Looper Player",
    subtitle: en("Your music, with synced lyrics"),
    developer: "Looper",
    category: "Music & Audio",
    price: "Free",
    description: en(
      "A music player that makes your own collection feel new again.\n\nWord-synced lyrics, album-coloured themes, and a library built around the music you already own.",
    ),
  },
  scenes: [
    shot("player", "Lyrics that move with you", "Word-synced lyrics, right on the player."),
    shot("home", "Your music, made new", "Fresh picks from your own collection."),
    shot("songs", "Themed by your album art", "The app takes on the color of what's playing."),
    shot("library", "Your whole collection", "Artists, albums, folders and genres in one place."),
    shot("queue", "Always know what's next", "Reorder, reshuffle and find related songs."),
  ],
};
