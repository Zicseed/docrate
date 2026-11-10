// DocRate — partner event advertisement (top bar on every page + card on the homepage).
//
// Edit only this file to change the event, or replace it for a future partner.
// Both the bar and the card disappear by themselves once `endsAt` has passed.
// To turn the advert off early, set `enabled: false`.
// When you change partner (or want everyone to see the bar again), change `id`:
// visitors who closed the bar only have that `id` hidden.

window.DOCRATE_PARTNER_EVENT = {
  enabled: true,
  id: "mediverse26",
  endsAt: "2026-11-16T00:00:00+04:00", // 16 Nov 2026, 00:00 Tbilisi time

  barText: "📢 MediVerse'26 Medical Conference: 14–15 Nov, Tbilisi. Registrations open! Register now →",
  barShort: "📢 MediVerse'26 · 14–15 Nov · Register →",

  title: "MediVerse'26: Registrations Now Open",
  subtitle: "International Medical Conference · Pulmonology & Critical Care",
  theme: "“Where Every Breath Is a Lifeline & Every Second Is Critical”",
  details: ["📍 Tbilisi, Georgia", "🗓️ 14–15 November 2026", "⏰ 10:00 AM – 6:00 PM"],
  packages: [
    { name: "Precision Cut Pack", text: "Essential conference experience with learning, networking & recognition" },
    { name: "Beyond the Scalpel Pack", text: "Enhanced learning & clinical skills" },
    { name: "Surgical Mastery Pack", text: "The ultimate experience with maximum hands-on clinical exposure & workshops" }
  ],

  organizer: "MedConnectsOrg",
  presentedBy: "Presented by MedConnectsOrg · in collaboration with Mediverse",
  registerUrl: "https://forms.gle/TpFhiUmREDqJ5Lit6",
  registerLabel: "Secure your spot",
  instagramUrl: "https://www.instagram.com/medconnectsorg",
  instagramLabel: "Follow on Instagram",
  email: "medconnectsorg@gmail.com"
};
