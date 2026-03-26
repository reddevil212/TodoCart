
# 🛒 TodoCart

TodoCart is a simple, modern, and extensible Flutter app for managing your daily tasks and to-dos. Built with clean architecture, Provider state management, and Material 3 design, it aims to be a delightful productivity companion.

---

## 🚀 Features

- Add, complete, and delete tasks
- Light & dark theme support (auto-switch or manual)
- Responsive UI with Material 3
- Bottom sheet for quick task creation (text or voice)
- Persistent state using Provider
- Clean, modular codebase for easy extension

---

## 🛠️ Getting Started

1. **Clone the repository:**
	```sh
	git clone https://github.com/reddevil212/TodoCart.git
	cd todocart
	```
2. **Install dependencies:**
	```sh
	flutter pub get
	```
3. **Run the app:**
	```sh
	flutter run
	```

---

## 📁 Project Structure

- `lib/`
  - `components/` – Reusable UI widgets (e.g., AddTaskBottomSheet)
  - `models/` – Data models (e.g., Task)
  - `provider/` – State management (TasksProvider, ThemeProvider)
  - `screens/` – App screens (HomePage, SettingsPage)
  - `utils/` – Utility functions

---

## 🧭 Next Goals

- [ ] Add persistent storage (e.g. SharedPreferences)
- [ ] Implement task editing
- [ ] Integrate voice-to-text(LLM based) for task creation
- [ ] Add notifications/reminders
- [ ] Improve accessibility and localization
- [ ] Write unit and widget tests
- [ ] Polish UI/UX and add animations

---

## 📚 Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Provider Package](https://pub.dev/packages/provider)

---

**Made with ❤️ by [reddevil212](https://github.com/reddevil212) using Flutter.**
