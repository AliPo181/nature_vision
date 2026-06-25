# TODO - Nature Vision tracking + memento upload fix

- [ ] Add offline outbox (SharedPreferences) for failed memento uploads.
- [ ] Implement upload retry/flush on app start and when returning to foreground.
- [ ] Extend ApiService.uploadMemento with better server-response logging and more robust id parsing.
- [x] Update backend payload schema expectations (field names) if required based on server response.

- [ ] Add event logging for upload success/failure + outbox queue/flush outcomes.
- [ ] Add a server-side delete schedule verification (confirm dashboard uses server timestamps).
- [ ] Test end-to-end: phone -> admin dashboard; confirm opens/session timing and memento records.

