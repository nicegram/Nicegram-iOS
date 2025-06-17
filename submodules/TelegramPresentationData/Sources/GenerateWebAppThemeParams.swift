public func generateWebAppThemeParams(_ theme: PresentationTheme) -> [String: Any] {
    return [
        "bg_color": Int32(bitPattern: theme.list.plainBackgroundColor.rgb),
        "secondary_bg_color": Int32(bitPattern: theme.list.blocksBackgroundColor.rgb),
        "text_color": Int32(bitPattern: theme.list.itemPrimaryTextColor.rgb),
        "hint_color": Int32(bitPattern: theme.list.itemSecondaryTextColor.rgb),
        "link_color": Int32(bitPattern: theme.list.itemAccentColor.rgb),
        "button_color": Int32(bitPattern: theme.list.itemCheckColors.fillColor.rgb),
        "button_text_color": Int32(bitPattern: theme.list.itemCheckColors.foregroundColor.rgb),
        "header_bg_color": Int32(bitPattern: theme.rootController.navigationBar.opaqueBackgroundColor.rgb),
        "bottom_bar_bg_color": Int32(bitPattern: theme.rootController.tabBar.backgroundColor.rgb),
        "accent_text_color": Int32(bitPattern: theme.list.itemAccentColor.rgb),
        "section_bg_color": Int32(bitPattern: theme.list.itemBlocksBackgroundColor.rgb),
        "section_header_text_color": Int32(bitPattern: theme.list.freeTextColor.rgb),
        "subtitle_text_color": Int32(bitPattern: theme.list.itemSecondaryTextColor.rgb),
        "destructive_text_color": Int32(bitPattern: theme.list.itemDestructiveColor.rgb),
        "section_separator_color": Int32(bitPattern: theme.list.itemBlocksSeparatorColor.rgb)
    ]
}
