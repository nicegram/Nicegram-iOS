import NGUtils

extension SettingsSearchableItem {
    // Copies every field, as upstream's withUpdatedTitle does: a field upstream adds must be added here too.
    func withAccountControlCheck() -> SettingsSearchableItem {
        SettingsSearchableItem(
            id: id,
            title: title,
            alternate: alternate,
            icon: icon,
            breadcrumbs: breadcrumbs,
            isVisible: isVisible,
            present: { context, navigationController, present in
                if context.nicegramBusiness.restrictsAccountControl() {
                    present(
                        .immediate,
                        accountControlAlert(context: context)
                    )
                    return
                }
                self.present(
                    context,
                    navigationController,
                    present
                )
            }
        )
    }
}

extension Array where Element == SettingsSearchableItem {
    func withAccountControlCheck(ids: Set<AnyHashable>) -> [SettingsSearchableItem] {
        map { ids.contains($0.id) ? $0.withAccountControlCheck() : $0 }
    }
}
