local DIALOG_NAME = 'PATHFINDER_CREATE_NEW_PATH'

ZO_Dialogs_RegisterCustomDialog(DIALOG_NAME, {
    title = {
        text = 'Create new path',
    },
    mainText = {
        text = '',
    },
    editBox = {
        defaultText = '',
        textType = TEXT_TYPE_ALL,
        instructions = nil,
        selectAll = true,
    },
    buttons = {
        {
            requiresTextInput = true,
            text = SI_OK,
            noReleaseOnClick = true,
            callback = function(dialog)
                local inputText = ZO_Dialogs_GetEditBoxText(dialog)
                if inputText and inputText ~= '' then
                    Pathfinder_AddPath(inputText)
                    ZO_Dialogs_ReleaseDialog(DIALOG_NAME)
                end
            end
        },
        {
            text = SI_DIALOG_CANCEL,
        },
    },
})
