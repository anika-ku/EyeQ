/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,jsx}'],
  theme: {
    extend: {
      colors: {
        brand: {
          50: '#eefaf6',
          100: '#d6f2e8',
          200: '#a9e3cf',
          400: '#2fae94',
          500: '#0f9b82',
          600: '#0c8a73', // primary teal (buttons, icons, logo)
          700: '#0a6f5c',
        },
        ink: {
          900: '#0f2333', // dark navy headings
          800: '#1c3245',
        },
        surface: {
          50: '#f5f8f7',  // page background
          100: '#eef4f2',
        },
        blush: {
          50: '#fbe9e7',  // prediction card background
          200: '#f3c9c4',
        },
      },
      fontFamily: {
        sans: ['"Plus Jakarta Sans"', 'ui-sans-serif', 'system-ui', 'sans-serif'],
        serif: ['"Fraunces"', 'ui-serif', 'Georgia', 'serif'],
      },
      borderRadius: {
        xl2: '1.25rem',
      },
    },
  },
  plugins: [],
}
