module.exports = {
  darkMode: "class",
  content: [
    "./*.{html,md}",
    "./_includes/**/*.{html,md}",
    "./_layouts/**/*.{html,md}",
    "./_articles/**/*.{html,md,markdown}",
    "./_books/**/*.{html,md,markdown}",
    "./{en,ja,ko,categories,tags}/**/*.{html,md}"
  ],
  theme: {
    extend: {}
  },
  plugins: [require("@tailwindcss/typography")]
};
