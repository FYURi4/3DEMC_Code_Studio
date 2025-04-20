if CLIENT then
    surface.CreateFont("Arial", {
        font = "Arial",
        size = 20,
        weight = 500,
        antialias = true,
    })
end

local CodeEditor = {
    Name = "3DEMC_Code_Studio",
    Version = "1.2",
    Author = "FYURI4",
    IsFullscreen = false,
    OriginalPos = {x = 0, y = 0},
    OriginalSize = {w = 0, h = 0},
    CurrentFile = nil,
    CurrentMenu = nil,
    FileSystem = nil,
    SupportedExtensions = {
        ".txt",
        ".lua",
        ".json",
        ".xml",
        ".md",
        ".html",
        ".css",
        ".js"
    }
}

clipboardText = ""
selectStart = nil
selectEnd = nil
selectAll = false

function CodeEditor:InitFileSystem()
    if not file.IsDir("3demc_code_studio", "DATA") then
        file.CreateDir("3demc_code_studio")
    end
    
    self.FileSystem = {
        CurrentDir = "3demc_code_studio",
        OpenFiles = {},
        RootDir = "3demc_code_studio"
    }
end

function CodeEditor:UpdateWindowElements()
    if not IsValid(self.Frame) then return end
    
    local w, h = self.Frame:GetSize()
    local titleBarH = 30
    
    -- Update title bar
    if IsValid(self.TitleBar) then
        self.TitleBar:SetWide(w)
    end
    
    -- Update buttons
    if IsValid(self.CloseBtn) then
        self.CloseBtn:SetPos(w - 30, 0)
    end
    
    if IsValid(self.FullscreenBtn) then
        self.FullscreenBtn:SetPos(w - 60, 0)
    end
    
    -- Update content
    if IsValid(self.ContentPanel) then
        self.ContentPanel:SetSize(w, h - titleBarH)
    end
    
    -- Update file browser and editor
    if IsValid(self.FileBrowser) then
        self.FileBrowser:SetSize(200, self.ContentPanel:GetTall() - 30)
    end
    
    if IsValid(self.CodePanel) then
        self.CodePanel:SetSize(self.ContentPanel:GetWide() - 205, self.ContentPanel:GetTall() - 30)
        self.CodePanel:SetPos(205, 0)
    end
    
    if IsValid(self.StatusBar) then
        self.StatusBar:SetPos(0, self.ContentPanel:GetTall() - 30)
        self.StatusBar:SetSize(self.ContentPanel:GetWide(), 30)
    end
    
    -- Update resize handles
    if not self.IsFullscreen then
        self:UpdateResizeHandles()
    end
end

function CodeEditor:UpdateResizeHandles()
    if not IsValid(self.Frame) or not self.ResizeHandles then return end
    if self.IsFullscreen then return end
    
    local w, h = self.Frame:GetSize()
    
    -- Top border
    if IsValid(self.ResizeHandles.top) then
        self.ResizeHandles.top:SetPos(0, 0)
        self.ResizeHandles.top:SetSize(w, 5)
        self.ResizeHandles.top:SetCursor("sizens")
    end
    
    -- Bottom border
    if IsValid(self.ResizeHandles.bottom) then
        self.ResizeHandles.bottom:SetPos(0, h - 5)
        self.ResizeHandles.bottom:SetSize(w, 5)
        self.ResizeHandles.bottom:SetCursor("sizens")
    end
    
    -- Left border
    if IsValid(self.ResizeHandles.left) then
        self.ResizeHandles.left:SetPos(0, 0)
        self.ResizeHandles.left:SetSize(5, h)
        self.ResizeHandles.left:SetCursor("sizewe")
    end
    
    -- Right border
    if IsValid(self.ResizeHandles.right) then
        self.ResizeHandles.right:SetPos(w - 5, 0)
        self.ResizeHandles.right:SetSize(5, h)
        self.ResizeHandles.right:SetCursor("sizewe")
    end
end

function CodeEditor:ToggleFullscreen()
    if not IsValid(self.Frame) then return end
    
    self.IsFullscreen = not self.IsFullscreen
    
    if self.IsFullscreen then
        -- Save original size and position
        self.OriginalPos.x, self.OriginalPos.y = self.Frame:GetPos()
        self.OriginalSize.w, self.OriginalSize.h = self.Frame:GetSize()
        
        -- Set to fullscreen
        self.Frame:SetPos(0, 0)
        self.Frame:SetSize(ScrW(), ScrH())
    else
        -- Restore original size and position
        self.Frame:SetPos(self.OriginalPos.x, self.OriginalPos.y)
        self.Frame:SetSize(self.OriginalSize.w, self.OriginalSize.h)
    end
    
    -- Update UI elements
    self:UpdateWindowElements()
end

function CodeEditor:CreateMainWindow()
    self:InitFileSystem()

    local MainWindow = vgui.Create("DFrame")
    MainWindow:SetSize(1900, 1000)
    MainWindow:Center()
    MainWindow:SetTitle("")
    MainWindow:ShowCloseButton(false)
    MainWindow:SetDraggable(false)
    MainWindow:MakePopup()
    
    -- Save reference to main window
    self.Frame = MainWindow
    
    -- Custom title bar
    local titleBar = vgui.Create("DPanel", MainWindow)
    titleBar:SetSize(MainWindow:GetWide(), 30)
    titleBar:SetPos(0, 0)
    titleBar.Paint = function(self, w, h)
        draw.RoundedBoxEx(4, 0, 0, w, h, Color(40, 40, 40), true, true, false, false)
        draw.SimpleText(CodeEditor.Name .. " v" .. CodeEditor.Version, "Arial", 10, h/2, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText("|", "Arial", 230, h/2, Color(100, 100, 100), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    self.TitleBar = titleBar
    
    -- Close button
    local closeBtn = vgui.Create("DButton", titleBar)
    closeBtn:SetSize(30, 30)
    closeBtn:SetPos(titleBar:GetWide() - 30, 0)
    closeBtn:SetText("X")
    closeBtn:SetFont("DermaDefaultBold")
    closeBtn:SetTextColor(Color(255, 255, 255))
    closeBtn.Paint = function(self, w, h)
        draw.RoundedBox(0, 0, 0, w, h, self:IsHovered() and Color(200, 50, 50) or Color(40, 40, 40))
    end
    closeBtn.DoClick = function()
        MainWindow:Close()
    end
    self.CloseBtn = closeBtn
    
    -- Fullscreen button
    local fullscreenBtn = vgui.Create("DButton", titleBar)
    fullscreenBtn:SetSize(30, 30)
    fullscreenBtn:SetPos(titleBar:GetWide() - 60, 0)
    fullscreenBtn:SetText("[]")
    fullscreenBtn:SetFont("DermaDefaultBold")
    fullscreenBtn:SetTextColor(Color(255, 255, 255))
    fullscreenBtn.Paint = function(self, w, h)
        draw.RoundedBox(0, 0, 0, w, h, self:IsHovered() and Color(60, 60, 60) or Color(40, 40, 40))
    end
    fullscreenBtn.DoClick = function()
        CodeEditor:ToggleFullscreen()
    end
    self.FullscreenBtn = fullscreenBtn
    
    -- Menu utilities
    local function AddCustomSpacer(menu)
        local option = menu:AddOption("", function() end)
        if IsValid(option) then
            option:SetEnabled(false)
            option.Paint = function(self, w, h)
                surface.SetDrawColor(40, 40, 40, 255)
                surface.DrawRect(4, h / 2, w - 8, 1)
            end
        end
    end

    local function AddCustomOption(menu, text, func)
        local option = menu:AddOption(text, func)
        if IsValid(option) then
            option:SetFont("Arial")
            option:SetTextColor(Color(255, 255, 255))
            option.Paint = function(self, w, h)
                draw.RoundedBox(0, 0, 0, w, h, self:IsHovered() and Color(60, 60, 60) or Color(30, 30, 30))
            end
        end
    end

    local function CreateCustomMenu(btn, items)
        if IsValid(CodeEditor.CurrentMenu) then
            CodeEditor.CurrentMenu:Remove()
        end

        local menu = DermaMenu()
        menu.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(30, 30, 30, 240))
        end
        menu.PaintOver = function(self, w, h)
            surface.SetDrawColor(40, 40, 40, 255)
            surface.DrawOutlinedRect(0, 0, w, h)
        end

        for _, v in ipairs(items) do
            if v == "SPACER" then
                AddCustomSpacer(menu)
            else
                AddCustomOption(menu, v[1], v[2])
            end
        end

        menu:Open()
        menu:SetPos(btn:LocalToScreen(0, btn:GetTall()))
        CodeEditor.CurrentMenu = menu
    end

    local function CreateMenuButton(parent, x, text, onClick)
        local btn = vgui.Create("DButton", parent)
        btn:SetSize(100, 30)
        btn:SetPos(x, 0)
        btn:SetText(text)
        btn:SetFont("Arial")
        btn:SetTextColor(Color(255, 255, 255))
        btn.Paint = function(self, w, h)
            draw.RoundedBox(0, 0, 0, w, h, self:IsHovered() and Color(60, 60, 60) or Color(40, 40, 40))
        end
        
        if onClick then
            btn.DoClick = onClick
        end
        
        return btn
    end

    -- File menu items
    local fileMenuItems = {
        {"Новый текстовый файл", function() CodeEditor:CreateNewFile() end},
        {"Новый файл...", function() print("Создать новый файл") end},
        {"Новое окно", function() print("Создать новое окно") end},
        "SPACER",
        {"Открыть файл", function() CodeEditor:OpenFileDialog() end},
        {"Открыть папку", function() print("Открыть папку") end},
        {"Открыть недавний", function() print("Открыть недавний файл") end},
        "SPACER",
        {"Сохранить", function() CodeEditor:SaveCurrentFile() end},
        {"Сохранить как...", function() print("Сохранить файл как...") end},
        {"Сохранить все", function() print("Сохранить все файлы") end},
        {"Автосохранение", function() print("Настройки автосохранения") end},
        "SPACER",
        {"Закрыть файл", function() CodeEditor:CloseCurrentFile() end},
        {"Закрыть окно", function() print("Закрыть текущее окно") end},
        {"Закрыть редактор", function() MainWindow:Close() end},
        "SPACER",
        {"Выход", function() MainWindow:Close() end}
    }

    -- Edit menu items
    local redactMenuItems = {
        {"Отменить", function() if IsValid(CodeEditor.CodeEntry) then CodeEditor.CodeEntry:Undo() end end},
        {"Повторить", function() if IsValid(CodeEditor.CodeEntry) then CodeEditor.CodeEntry:Redo() end end},
        "SPACER",
        {"Вырезать", function() if IsValid(CodeEditor.CodeEntry) then CodeEditor.CodeEntry:Cut() end end},
        {"Копировать", function() if IsValid(CodeEditor.CodeEntry) then CodeEditor.CodeEntry:Copy() end end},
        {"Вставить", function() if IsValid(CodeEditor.CodeEntry) then CodeEditor.CodeEntry:Paste() end end},
        {"Удалить", function() if IsValid(CodeEditor.CodeEntry) then CodeEditor.CodeEntry:Clear() end end},
        "SPACER",
        {"Найти", function() print("Найти текст") end},
        {"Заменить", function() print("Заменить текст") end},
        {"Найти и заменить", function() print("Заменить текст") end},
        "SPACER",
        {"Сделать строку комментарием", function() print("Комментировать строку") end},
        {"Сделать блок комментарием", function() print("Комментировать блок") end}
    }

    -- Selection menu items
    local SelectionMenuItems = {
        {"Выбрать ВСЕ", function() if IsValid(CodeEditor.CodeEntry) then CodeEditor.CodeEntry:SelectAll() end end},
        "SPACER",
        {"Копировать линию Вверх", function() print("Копировать линию вверх") end},
        {"Копировать линию Вниз", function() print("Копировать линию вниз") end},
        {"Передвижение линии Вверх", function() print("Передвинуть линию вверх") end},
        {"Передвижение линии Вниз", function() print("Передвинуть линию вниз") end},
        {"Дублировать Выделение", function() print("Дублировать выделение") end}
    }

    -- View menu items
    local ViewMenuItems = {
        {"Найти", function() print("Поиск") end},
        {"Найти строчку", function() print("Поиск") end},
    }

    -- Settings menu items
    local SettingsMenuItems = {
        {"Тема", function() print("Настройки темы") end},
        {"Шрифт", function() print("Настройки шрифта") end},
        {"Горячие клавиши", function() print("Настройки горячих клавиш") end},
        "SPACER",
        {"Настройки редактора", function() print("Настройки редактора") end}
    }

    -- Help menu items
    local HelpMenuItems = {
        {"Документация", function() print("Открыть документацию") end},
        {"О программе", function() 
            Derma_Message(CodeEditor.Name .. " версия " .. CodeEditor.Version .. "\nАвтор: " .. CodeEditor.Author, "О программе", "OK")
        end}
    }

    local OtladkaMenuItems = {
        {"Запустить текущий код", function() print("Запуск кода") end}
    }

    -- Create menu buttons
    local fileBtn = CreateMenuButton(titleBar, 230, "Файл", nil)
    fileBtn.DoClick = function()
        CreateCustomMenu(fileBtn, fileMenuItems)
    end

    local redactBtn = CreateMenuButton(titleBar, 330, "Редакт...", nil)
    redactBtn.DoClick = function()
        CreateCustomMenu(redactBtn, redactMenuItems)
    end

    local SelectBtn = CreateMenuButton(titleBar, 430, "Выбор", nil)
    SelectBtn.DoClick = function()
        CreateCustomMenu(SelectBtn, SelectionMenuItems)
    end

    local ViewBtn = CreateMenuButton(titleBar, 530, "Найти", nil)
    ViewBtn.DoClick = function()
        CreateCustomMenu(ViewBtn, ViewMenuItems)
    end

    local SettingsBtn = CreateMenuButton(titleBar, 630, "Настройки", nil)
    SettingsBtn.DoClick = function()
        CreateCustomMenu(SettingsBtn, SettingsMenuItems)
    end

    local OtladkaBtn = CreateMenuButton(titleBar, 730, "Отладка", nil)
    OtladkaBtn.DoClick = function()
        CreateCustomMenu(OtladkaBtn, OtladkaMenuItems)
    end

    local HelpBtn = CreateMenuButton(titleBar, 830, "Помощь", nil)
    HelpBtn.DoClick = function()
        CreateCustomMenu(HelpBtn, HelpMenuItems)
    end
    -- Save menu buttons
    self.MenuButtons = {fileBtn, redactBtn, SelectBtn, ViewBtn, SettingsBtn, HelpBtn}

    -- Content area
    local content = vgui.Create("DPanel", MainWindow)
    content:SetSize(MainWindow:GetWide(), MainWindow:GetTall() - titleBar:GetTall())
    content:SetPos(0, titleBar:GetTall())
    content.Paint = function(self, w, h)
        draw.RoundedBoxEx(4, 0, 0, w, h, Color(30, 30, 30), false, false, true, true)
    end
    self.ContentPanel = content

---ЛЕВАЯ ЧАСТЬ CODE STUDIO---
local fileBrowser = vgui.Create("DScrollPanel", content)
fileBrowser:SetSize(200, content:GetTall() - 30)
fileBrowser:SetPos(0, 0)
fileBrowser.Paint = function(self, w, h)
    draw.RoundedBox(0, 0, 0, w, h, Color(40, 40, 40))
end
self.FileBrowser = fileBrowser

-- Кнопки управления
local buttonPanel = vgui.Create("DPanel", fileBrowser)
buttonPanel:SetSize(180, 30)
buttonPanel:SetPos(10, 5)
buttonPanel.Paint = function() end

-- Кнопка обновления
local refreshBtn = vgui.Create("DButton", buttonPanel)
refreshBtn:SetSize(25, 25)
refreshBtn:SetPos(0, 0)
refreshBtn:SetImage("RES.png")  -- Путь к изображению для обновления
refreshBtn.DoClick = function()
    CodeEditor:RefreshFileTree()
end

-- Кнопка создания файла
local newFileBtn = vgui.Create("DButton", buttonPanel)
newFileBtn:SetSize(25, 25)
newFileBtn:SetPos(30, 0)
newFileBtn:SetImage("FILE.png")  -- Путь к изображению для создания файла
newFileBtn.DoClick = function()
    CodeEditor:CreateNewFileDialog()
end

-- Кнопка создания папки
local newFolderBtn = vgui.Create("DButton", buttonPanel)
newFolderBtn:SetSize(25, 25)
newFolderBtn:SetPos(60, 0)
newFolderBtn:SetImage("PAPKA.png")  -- Путь к изображению для создания папки
newFolderBtn.DoClick = function()
    CodeEditor:CreateNewFolderDialog()
end

-- File tree
local fileTree = vgui.Create("DTree", fileBrowser)
fileTree:SetSize(180, fileBrowser:GetTall() - 40)
fileTree:SetPos(10, 40)
fileTree:SetIndentSize(10)
fileTree:SetBackgroundColor(Color(40, 40, 40))
self.FileTree = fileTree

-- Custom folder icon
fileTree.OnNodeCreated = function(self, node)
    if node.IsFolder then
        node:SetIcon("icon16/folder.png")
    else
        node:SetIcon("icon16/page_white_text.png")
    end
    node.Label:SetTextColor(Color(200, 200, 200))
end


-- Function to populate the tree
-- Функция для безопасного удаления файла
function SafeDeleteFile(filePath)
    if file.Exists(filePath, "DATA") then
        -- Пытаемся удалить файл
        return file.Delete(filePath)
    end
    return false
end

-- Метод для заполнения дерева файлов
function CodeEditor:PopulateFileTree(path, parentNode)
    local files, folders = file.Find(path .. "/*", "DATA")
    
    -- Добавляем папки первыми
    table.sort(folders)
    for _, folder in ipairs(folders) do
        local folderPath = path .. "/" .. folder
        local folderNode = parentNode:AddNode(folder)
        folderNode:SetIcon("icon16/folder.png")
        folderNode:SetExpanded(false)
        folderNode.Path = folderPath
        folderNode.IsFolder = true
        
        -- Рекурсивно заполняем подкаталоги
        self:PopulateFileTree(folderPath, folderNode)
        
        -- Контекстное меню для папки
        folderNode.DoRightClick = function()
            print("Правый клик на папке: " .. folderNode:GetText())  -- Отладочный вывод
            local menu = DermaMenu()
            
            -- Добавляем опцию для удаления папки
            menu:AddOption("Удалить папку", function()
                Derma_Query("Вы уверены, что хотите удалить папку \"" .. folderNode:GetText() .. "\"?", "Подтверждение",
                    "Да", function()
                        -- Удаляем папку рекурсивно
                        if DeleteFolderRecursive(folderNode.Path) then
                            print("Папка успешно удалена: " .. folderNode.Path)
                            CodeEditor:RefreshFileTree()
                        else
                            Derma_Message("Не удалось удалить папку!", "Ошибка", "OK")
                        end
                    end,
                    "Нет", function() end
                )
            end)
            
            menu:Open()
        end
    end
    
    -- Добавляем файлы
    table.sort(files)
    for _, file in ipairs(files) do
        local filePath = path .. "/" .. file
        local fileNode = parentNode:AddNode(file)
        fileNode:SetIcon("icon16/page_white_text.png")
        fileNode.Path = filePath
        fileNode.IsFolder = false
        
        -- Обработка клика по файлу
        fileNode.DoClick = function()
            CodeEditor:OpenFile(filePath)
        end
        
        -- Контекстное меню для файлов
        fileNode.DoRightClick = function()
            print("Правый клик на файле: " .. fileNode:GetText())  -- Отладочный вывод
            local menu = DermaMenu()
        
            -- Добавляем опцию для удаления файла
            menu:AddOption("Удалить файл", function()
                Derma_Query("Вы уверены, что хотите удалить файл \"" .. fileNode:GetText() .. "\"?", "Подтверждение",
                    "Да", function()
                        -- Удаляем файл
                        if SafeDeleteFile(fileNode.Path) then
                            print("Файл успешно удалён: " .. fileNode.Path)
                            CodeEditor:RefreshFileTree()
                        else
                            Derma_Message("Не удалось удалить файл!", "Ошибка", "OK")
                        end
                    end,
                    "Нет", function() end
                )
            end)
        
            menu:Open()
        end
    end
end


function CodeEditor:RefreshFileTree()
    if not IsValid(self.FileTree) then return end
    self.FileTree:Clear()
    -- Заполняем дерево файлов
    self:PopulateFileTree(self.FileSystem.CurrentDir, self.FileTree)
end

-- Функция для рекурсивного удаления папки
function DeleteFolderRecursive(folderPath)
    -- Сначала удаляем все файлы в папке
    local files, folders = file.Find(folderPath .. "/*", "DATA")
    
    for _, file in ipairs(files) do
        local filePath = folderPath .. "/" .. file
        if not file.Delete(filePath) then
            return false -- Не удалось удалить файл
        end
    end
    
    -- Затем рекурсивно удаляем все подпапки
    for _, folder in ipairs(folders) do
        local subFolderPath = folderPath .. "/" .. folder
        if not DeleteFolderRecursive(subFolderPath) then
            return false -- Не удалось удалить подпапку
        end
    end
    
    -- Наконец, удаляем саму папку
    return file.Delete(folderPath)
end

-- Функция для безопасного удаления файла
function SafeDeleteFile(filePath)
    return file.Delete(filePath)
end

function CodeEditor:GetSelectedFolder()
    if not IsValid(self.FileTree) then return self.FileSystem.CurrentDir end
    
    local selectedNode = self.FileTree:GetSelectedItem()
    if not selectedNode then return self.FileSystem.CurrentDir end
    
    return selectedNode.IsFolder and selectedNode.Path or self.FileSystem.CurrentDir
end

-- Function to create new folder dialog
function CodeEditor:CreateNewFolderDialog()
    local currentPath = self:GetSelectedFolder() -- Используем выбранную папку вместо текущей директории
    
    local frame = vgui.Create("DFrame")
    frame:SetSize(300, 150)
    frame:Center()
    frame:SetTitle("Создать папку")
    frame:MakePopup()
    
    local nameEntry = vgui.Create("DTextEntry", frame)
    nameEntry:SetPlaceholderText("Введите имя папки...")
    nameEntry:Dock(TOP)
    nameEntry:DockMargin(5, 5, 5, 5)
    
    local createBtn = vgui.Create("DButton", frame)
    createBtn:Dock(BOTTOM)
    createBtn:SetText("Создать")
    createBtn.DoClick = function()
        local folderName = nameEntry:GetText()
        if folderName and folderName ~= "" then
            local fullPath = currentPath .. "/" .. folderName
            if not file.IsDir(fullPath, "DATA") then
                file.CreateDir(fullPath)
                CodeEditor:RefreshFileTree()
                frame:Close()
            else
                Derma_Message("Папка с таким именем уже существует!", "Ошибка", "OK")
            end
        end
    end
end

-- Function to create new file dialog
function CodeEditor:CreateNewFileDialog()
    local currentPath = self:GetSelectedFolder()
    
    local frame = vgui.Create("DFrame")
    frame:SetSize(350, 200) -- Увеличиваем высоту для нового элемента
    frame:Center()
    frame:SetTitle("Создать файл")
    frame:MakePopup()
    
    -- Поле для имени файла
    local nameEntry = vgui.Create("DTextEntry", frame)
    nameEntry:SetPlaceholderText("Введите имя файла (без расширения)...")
    nameEntry:Dock(TOP)
    nameEntry:DockMargin(5, 5, 5, 5)
    
    -- Выпадающий список для расширений
    local extensionCombo = vgui.Create("DComboBox", frame)
    extensionCombo:Dock(TOP)
    extensionCombo:DockMargin(5, 0, 5, 5)
    extensionCombo:SetValue("Выберите расширение")
    
    -- Добавляем варианты расширений
    for _, ext in ipairs(self.SupportedExtensions) do
        extensionCombo:AddChoice(ext)
    end
    
    -- Кнопка создания
    local createBtn = vgui.Create("DButton", frame)
    createBtn:Dock(BOTTOM)
    createBtn:SetText("Создать")
    createBtn.DoClick = function()
        local fileName = nameEntry:GetText()
        local _, selectedExtension = extensionCombo:GetSelected()
        
        if fileName and fileName ~= "" then
            -- Если пользователь не выбрал расширение, используем .txt по умолчанию
            if not selectedExtension or selectedExtension == "Выберите расширение" then
                selectedExtension = ".txt"
            end
            
            -- Удаляем точку, если пользователь её ввел
            fileName = fileName:gsub("%..+$", "")
            
            local fullPath = currentPath .. "/" .. fileName .. selectedExtension
            
            if not file.Exists(fullPath, "DATA") then
                -- Начальное содержимое в зависимости от типа файла
                local initialContent = ""
                if selectedExtension == ".lua" then
                    initialContent = "-- Новый Lua файл\n-- Начните писать код здесь..."
                elseif selectedExtension == ".json" then
                    initialContent = "{\n    \n}"
                else
                    initialContent = "-- Новый файл\n-- Начните писать код здесь..."
                end
                
                file.Write(fullPath, initialContent)
                CodeEditor:RefreshFileTree()
                CodeEditor:OpenFile(fullPath)
                frame:Close()
            else
                Derma_Message("Файл с таким именем уже существует!", "Ошибка", "OK")
            end
        else
            Derma_Message("Введите имя файла!", "Ошибка", "OK")
        end
    end
end

-- Initial population
CodeEditor:RefreshFileTree()
---ЛЕВАЯ ЧАСТЬ CODE STUDIO КОНЕЦ---
---ПРАВАЯ ЧАСТЬ CODE STUDIO---
    
    -- Создаем главный контейнер с скроллом для редактора кода
    local editorScrollPanel = vgui.Create("DScrollPanel", content)
    editorScrollPanel:SetSize(content:GetWide() - 205, content:GetTall() - 30)
    editorScrollPanel:SetPos(205, 0)
    editorScrollPanel.Paint = function(self, w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(25, 25, 25))
    end
    self.EditorScrollPanel = editorScrollPanel

    local logoPanel = vgui.Create("DPanel", editorScrollPanel)
    logoPanel:SetSize(800, 800) -- Размер логотипа
    logoPanel:SetPos(editorScrollPanel:GetWide() - 1100, editorScrollPanel:GetTall()-900) -- Позиция (правый верхний угол с отступом)
    logoPanel:SetMouseInputEnabled(false) -- Чтобы клики проходили сквозь логотип
    logoPanel.Paint = function(self, w, h)
        -- Прозрачный фон
        draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, 0))
        surface.SetMaterial(Material("LOGOTYPE.png"))
        surface.SetDrawColor(255, 255, 255, 5) -- Полупрозрачный
        surface.DrawTexturedRect(0, 0, w, h)
    end
    logoPanel:SetParent(content) -- Теперь логотип будет привязан к основному контейнеру
    logoPanel:MoveToFront() 

    -- Создаем панель для содержимого редактора
    local editorContent = vgui.Create("DPanel", editorScrollPanel)
    editorContent:SetSize(editorScrollPanel:GetWide(), editorScrollPanel:GetTall())
    editorContent.Paint = function() end
    editorScrollPanel:AddItem(editorContent)

    local code = ""
    local caretPos = 1
    local isFocused = true
    local lastCharTime = 0
    local charDelay = 0.05
    local lastKey = nil

    surface.CreateFont("CodeFont", {
        font = "Courier New",
        size = 18,
        weight = 500,
        antialias = true,
    })
    
    local colors = {
        ["keyword"] = Color(255, 100, 100),
        ["string"] = Color(100, 255, 100),
        ["number"] = Color(100, 200, 255),
        ["comment"] = Color(150, 150, 150),
        ["default"] = Color(255, 255, 255),
    }

    local lua_keywords = {
        ["if"] = true, ["then"] = true, ["else"] = true, ["elseif"] = true,
        ["end"] = true, ["for"] = true, ["while"] = true, ["do"] = true,
        ["function"] = true, ["local"] = true, ["return"] = true, ["break"] = true,
        ["and"] = true, ["or"] = true, ["not"] = true, ["in"] = true,
    }

    local function ParseLuaLine(line)
        local tokens = {}
        local i = 1

        while i <= #line do
            local c = line:sub(i, i)

            if line:sub(i, i+1) == "--" then
                table.insert(tokens, {text = line:sub(i), color = colors.comment})
                break
            elseif c == "\"" or c == "'" then
                local closing = line:find(c, i+1, true)
                if closing then
                    table.insert(tokens, {text = line:sub(i, closing), color = colors.string})
                    i = closing + 1
                else
                    table.insert(tokens, {text = line:sub(i), color = colors.string})
                    break
                end
            elseif c:match("%d") then
                local num = line:match("^%d+%.?%d*", i)
                if num then
                    table.insert(tokens, {text = num, color = colors.number})
                    i = i + #num
                else
                    i = i + 1
                end
            elseif c:match("[%a_]") then
                local word = line:match("^[%a_][%w_]*", i)
                if word then
                    local color = lua_keywords[word] and colors.keyword or colors.default
                    table.insert(tokens, {text = word, color = color})
                    i = i + #word
                else
                    i = i + 1
                end
            else
                table.insert(tokens, {text = c, color = colors.default})
                i = i + 1
            end
        end

        return tokens
    end

    editorContent.Paint = function(self, w, h)
        if not isFocused then return end

        local gutterWidth = 40 -- ширина для номеров строк
        draw.RoundedBox(8, 0, 0, w, h, Color(30, 30, 30, 255)) -- x и y = 0, потому что в Paint панели

        surface.SetFont("CodeFont")
        local lines = string.Explode("\n", code)

        for i, line in ipairs(lines) do
            local tx = gutterWidth + 5
            local ty = 10 + (i - 1) * 20

            local lineNumber = tostring(i) .. ":"
            surface.SetTextColor(180, 180, 180)
            surface.SetTextPos(5, ty)
            surface.DrawText(lineNumber)

            local tokens = ParseLuaLine(line)
            for _, token in ipairs(tokens) do
                surface.SetTextColor(token.color)
                surface.SetTextPos(tx, ty)
                surface.DrawText(token.text)
                tx = tx + surface.GetTextSize(token.text)
            end
        end

        -- Курсор
        local time = SysTime()
        if math.floor(time * 2) % 2 == 0 then -- мигание 2 раза в секунду
            local cursorLine, cursorX = 1, 0
            local total = 0
            for i, line in ipairs(lines) do
                if caretPos <= total + #line + 1 then
                    cursorLine = i
                    cursorX = caretPos - total - 1
                    break
                end
                total = total + #line + 1
            end

            local tx = gutterWidth + 5
            local ty = 10 + (cursorLine - 1) * 20
            local before = string.sub(lines[cursorLine] or "", 1, cursorX)
            tx = tx + surface.GetTextSize(before)

            surface.SetDrawColor(255, 255, 255, 255)
            surface.DrawRect(tx, ty, 1, 18)
        end
    end 

    hook.Add("Think", "CodeEditor_Input", function()
        if not isFocused then return end
    
        local curTime = CurTime()
        if curTime - lastCharTime < charDelay then return end
    
        local delayTable = {
            letter = 0.1,
            symbol = 0.1,
            [KEY_SPACE] = 0.1,
            [KEY_ENTER] = 0.18,
            [KEY_TAB] = 0.18,
            [KEY_BACKSPACE] = 0.1,
            default = 0.05,
        }
    
        local shift = input.IsKeyDown(KEY_LSHIFT) or input.IsKeyDown(KEY_RSHIFT)
        local ctrl = input.IsKeyDown(KEY_LCONTROL) or input.IsKeyDown(KEY_RCONTROL)
    
        local keyMap = {
            ["1"] = {"1", "!"}, ["2"] = {"2", "@"}, ["3"] = {"3", "#"}, ["4"] = {"4", "$"},
            ["5"] = {"5", "%"}, ["6"] = {"6", "^"}, ["7"] = {"7", "&"}, ["8"] = {"8", "*"},
            ["9"] = {"9", "("}, ["0"] = {"0", ")"}, ["-"] = {"-", "_"}, ["="] = {"=", "+"},
            ["["] = {"[", "{"}, ["]"] = {"]", "}"}, ["\\"] = {"\\", "|"},
            [";"] = {";", ":"}, ["'"] = {"'", "\""}, [","] = {",", "<"},
            ["."] = {".", ">"}, ["/"] = {"/", "?"}, ["`"] = {"`", "~"},
        }
    
        -- Выделение всего
        if ctrl and input.IsKeyDown(KEY_A) then
            if lastKey ~= KEY_A then
                selectStart = 1
                selectEnd = #code + 1
                caretPos = selectEnd
                selectAll = true
                lastCharTime = curTime
                lastKey = KEY_A
                charDelay = 0.2
                return
            end
        end
    
        -- Копирование
        if ctrl and input.IsKeyDown(KEY_C) then
            if lastKey ~= KEY_C and selectAll then
                clipboardText = code:sub(selectStart, selectEnd - 1)
                lastCharTime = curTime
                lastKey = KEY_C
                charDelay = 0.2
                return
            end
        end
    
        -- Вырезание
        if ctrl and input.IsKeyDown(KEY_X) then
            if lastKey ~= KEY_X and selectAll then
                clipboardText = code:sub(selectStart, selectEnd - 1)
                code = ""
                caretPos = 1
                selectStart = nil
                selectEnd = nil
                selectAll = false
                lastCharTime = curTime
                lastKey = KEY_X
                charDelay = 0.2
                return
            end
        end
    
        -- Вставка
        if ctrl and input.IsKeyDown(KEY_V) then
            if lastKey ~= KEY_V then
                if selectAll then
                    code = clipboardText
                    caretPos = #code + 1
                else
                    code = string.sub(code, 1, caretPos - 1) .. clipboardText .. string.sub(code, caretPos)
                    caretPos = caretPos + #clipboardText
                end
                selectAll = false
                lastCharTime = curTime
                lastKey = KEY_V
                charDelay = 0.1
                return
            end
        end
    
        if not ctrl and (lastKey == KEY_A or lastKey == KEY_C or lastKey == KEY_X or lastKey == KEY_V) then
            lastKey = nil
        end
    
        for i = 1, 255 do
            if input.IsKeyDown(i) then
                local char = input.GetKeyName(i)
                if not char then continue end
    
                local delay
                if i == lastKey then
                    local keyType = delayTable[i] and i
                        or (char:match("^[a-zA-Z]$") and "letter")
                        or (char:match("^[%p%d]$") and "symbol")
                        or "default"
                    delay = delayTable[keyType] or delayTable.default
                    if curTime - lastCharTime < delay then return end
                end
    
                local function replaceSelection()
                    if selectAll then
                        code = ""
                        caretPos = 1
                        selectStart = nil
                        selectEnd = nil
                        selectAll = false
                    end
                end
    
                if #char == 1 and char:match("%a") then
                    replaceSelection()
                    local c = shift and string.upper(char) or string.lower(char)
                    code = string.sub(code, 1, caretPos - 1) .. c .. string.sub(code, caretPos)
                    caretPos = caretPos + 1
                    lastCharTime = curTime
                    lastKey = i
                    charDelay = delayTable.letter
                    return
                end
    
                if #char == 1 and keyMap[char] then
                    replaceSelection()
                    local c = shift and keyMap[char][2] or keyMap[char][1]
                    local pairMap = {["\""] = "\"", ["'"] = "'", ["("] = ")", ["["] = "]", ["{"] = "}"}
                    if pairMap[c] then
                        code = string.sub(code, 1, caretPos - 1) .. c .. pairMap[c] .. string.sub(code, caretPos)
                        caretPos = caretPos + 1
                    else
                        code = string.sub(code, 1, caretPos - 1) .. c .. string.sub(code, caretPos)
                        caretPos = caretPos + 1
                    end
                    lastCharTime = curTime
                    lastKey = i
                    charDelay = delayTable.symbol
                    return
                end
    
                if i == KEY_SPACE then
                    replaceSelection()
                    code = string.sub(code, 1, caretPos - 1) .. " " .. string.sub(code, caretPos)
                    caretPos = caretPos + 1
                    lastCharTime = curTime
                    lastKey = i
                    charDelay = delayTable[KEY_SPACE]
                    return
                elseif i == KEY_TAB then
                    replaceSelection()
                    code = string.sub(code, 1, caretPos - 1) .. "\t" .. string.sub(code, caretPos)
                    caretPos = caretPos + 1
                    lastCharTime = curTime
                    lastKey = i
                    charDelay = delayTable[KEY_TAB]
                    return
                elseif i == KEY_ENTER then
                    replaceSelection()
                    code = string.sub(code, 1, caretPos - 1) .. "\n" .. string.sub(code, caretPos)
                    caretPos = caretPos + 1
                    lastCharTime = curTime
                    lastKey = i
                    charDelay = delayTable[KEY_ENTER]
                    return
                elseif i == KEY_BACKSPACE then
                    if selectAll then
                        replaceSelection()
                    elseif caretPos > 1 then
                        local prevChar = code:sub(caretPos - 1, caretPos - 1)
                        local nextChar = code:sub(caretPos, caretPos)
                        local pairs = {["\""] = "\"", ["'"] = "'", ["("] = ")", ["["] = "]", ["{"] = "}"}
                        if pairs[prevChar] and nextChar == pairs[prevChar] then
                            code = string.sub(code, 1, caretPos - 2) .. string.sub(code, caretPos + 1)
                            caretPos = caretPos - 1
                        else
                            code = string.sub(code, 1, caretPos - 2) .. string.sub(code, caretPos)
                            caretPos = caretPos - 1
                        end
                    end
                    lastCharTime = curTime
                    lastKey = i
                    charDelay = delayTable[KEY_BACKSPACE]
                    return
                elseif i == KEY_LEFT then
                    caretPos = math.max(caretPos - 1, 1)
                    selectAll = false
                    lastCharTime = curTime
                    lastKey = i
                    charDelay = delayTable.default
                    return
                elseif i == KEY_RIGHT then
                    caretPos = math.min(caretPos + 1, #code + 1)
                    selectAll = false
                    lastCharTime = curTime
                    lastKey = i
                    charDelay = delayTable.default
                    return
                end
            end
        end
    
        lastKey = nil
    end)
    
---ПРАВАЯ ЧАСТЬ CODE STUDIO КОНЕЦ---

    -- Status bar
    local statusBar = vgui.Create("DPanel", content)
    statusBar:SetSize(content:GetWide(), 30)
    statusBar:SetPos(0, content:GetTall() - 30)
    statusBar.Paint = function(self, w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(40, 40, 40))
        draw.SimpleText("Готов", "Arial", 10, h/2, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end
    self.StatusBar = statusBar

    -- Create resize handles
    self.ResizeHandles = {
        top = vgui.Create("DPanel", MainWindow),
        bottom = vgui.Create("DPanel", MainWindow),
        left = vgui.Create("DPanel", MainWindow),
        right = vgui.Create("DPanel", MainWindow)
    }
    
    -- Configure resize handles
    for _, panel in pairs(self.ResizeHandles) do
        panel:SetMouseInputEnabled(true)
        panel.Paint = function() end
    end
    
    -- Initialize resize handles
    self:UpdateResizeHandles()
    
    -- Window movement logic
    local moveX, moveY, isDragging = 0, 0, false
    
    titleBar.OnMousePressed = function(self, code)
        if code == MOUSE_LEFT and not CodeEditor.IsFullscreen then
            local x, y = self:LocalToScreen(0, 0)
            moveX = gui.MouseX() - x
            moveY = gui.MouseY() - y
            isDragging = true
            self:MouseCapture(true)
        end
    end
    
    titleBar.OnMouseReleased = function(self)
        isDragging = false
        self:MouseCapture(false)
    end
    
    titleBar.OnCursorMoved = function(self, cursorX, cursorY)
        if isDragging and not CodeEditor.IsFullscreen then
            local x = gui.MouseX() - moveX
            local y = gui.MouseY() - moveY
            MainWindow:SetPos(x, y)
        end
    end
    
    -- Resize handlers
    local isResizing = false
    local resizeType = ""
    local resizeStartPos = {x = 0, y = 0}
    local resizeStartSize = {w = 0, h = 0}
    
    -- Assign handlers to all resize handles
    local function SetupResizeHandle(handle, type)
        handle.OnMousePressed = function(self, code)
            if code == MOUSE_LEFT then
                isResizing = true
                resizeType = type
                resizeStartPos.x, resizeStartPos.y = MainWindow:GetPos()
                resizeStartSize.w, resizeStartSize.h = MainWindow:GetSize()
                self:MouseCapture(true)
            end
        end
    end
    
    SetupResizeHandle(self.ResizeHandles.top, "top")
    SetupResizeHandle(self.ResizeHandles.bottom, "bottom")
    SetupResizeHandle(self.ResizeHandles.left, "left")
    SetupResizeHandle(self.ResizeHandles.right, "right")
    
    -- Mouse release handler
    gui.EnableScreenClicker(true)
    
    hook.Add("VGUIMouseReleased", "CodeEditorResizeStop", function()
        if isResizing then
            isResizing = false
            for _, handle in pairs(CodeEditor.ResizeHandles) do
                if IsValid(handle) then
                    handle:MouseCapture(false)
                end
            end
        end
    end)
    
    -- Main resize loop
    MainWindow.Think = function()
        if isResizing and not CodeEditor.IsFullscreen then
            local mouseX, mouseY = gui.MouseX(), gui.MouseY()
            
            local x, y = resizeStartPos.x, resizeStartPos.y
            local w, h = resizeStartSize.w, resizeStartSize.h
            
            -- Handle different resize types
            if resizeType == "top" then
                local newHeight = resizeStartSize.h - (mouseY - resizeStartPos.y)
                if newHeight >= 300 then
                    y = mouseY
                    h = newHeight
                end
            elseif resizeType == "bottom" then
                h = resizeStartSize.h + (mouseY - (resizeStartPos.y + resizeStartSize.h))
            elseif resizeType == "left" then
                local newWidth = resizeStartSize.w - (mouseX - resizeStartPos.x)
                if newWidth >= 400 then
                    x = mouseX
                    w = newWidth
                end
            elseif resizeType == "right" then
                w = resizeStartSize.w + (mouseX - (resizeStartPos.x + resizeStartSize.w))
            end
            
            -- Apply minimum sizes
            w = math.max(400, w)
            h = math.max(300, h)
            
            -- Update window position and size
            MainWindow:SetPos(x, y)
            MainWindow:SetSize(w, h)
            
            -- Update UI elements
            CodeEditor:UpdateWindowElements()
        end
    end
    
    -- Initialize file system and refresh file list
    self:InitFileSystem()
    self:RefreshFileList()
    
    return MainWindow
end

function CodeEditor:RefreshFileList()
    if not IsValid(self.FileList) then return end
    
    self.FileList:Clear()
    
    local files, folders = file.Find(self.FileSystem.CurrentDir .. "/*", "DATA")
    
    -- Add folders first
    for _, folder in ipairs(folders) do
        self.FileList:AddLine("[Папка] " .. folder)
    end
    
    -- Then add files
    for _, filename in ipairs(files) do
        self.FileList:AddLine(filename)
    end
end

function CodeEditor:OpenFile(filename)
    if not filename or filename == "" then return end
    
    local path = self.FileSystem.CurrentDir .. "/" .. filename
    if not file.Exists(path, "DATA") then return end
    
    local content = file.Read(path, "DATA")
    if not content then return end
    
    self.CurrentFile = filename
    self.CodeEntry:SetText(content)
    
    -- Update line numbers
    local lineCount = select(2, string.gsub(content, "\n", "")) + 1
    local numbers = ""
    for i = 1, lineCount do
        numbers = numbers .. i .. "\n"
    end
    self.LineNumbers:SetText(numbers)
end

function CodeEditor:SaveCurrentFile()
    if not self.CurrentFile then
        self:SaveFileDialog()
        return
    end
    
    -- Проверяем, есть ли расширение у файла
    if not self.CurrentFile:match("%..+$") then
        -- Если нет, добавляем .txt по умолчанию
        self.CurrentFile = self.CurrentFile .. ".txt"
    end
    
    local path = self.FileSystem.CurrentDir .. "/" .. self.CurrentFile
    file.Write(path, self.CodeEntry:GetText())
    
    -- Обновляем статус бар
    if IsValid(self.StatusBar) then
        self.StatusBar.Paint = function(self, w, h)
            draw.RoundedBox(0, 0, 0, w, h, Color(40, 40, 40))
            draw.SimpleText("Файл сохранен: " .. path, "Arial", 10, h/2, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
    end
end

function CodeEditor:CloseCurrentFile()
    self.CurrentFile = nil
    self.CodeEntry:SetText("")
    self.LineNumbers:SetText("1")
    
    -- Update status bar
    if IsValid(self.StatusBar) then
        self.StatusBar.Paint = function(self, w, h)
            draw.RoundedBox(0, 0, 0, w, h, Color(40, 40, 40))
            draw.SimpleText("Готов", "Arial", 10, h/2, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
    end
end

function CodeEditor:CreateNewFile()
    self:CloseCurrentFile()
    self.CodeEntry:SetText("-- Новый файл\n-- Начните писать код здесь...")
    self.LineNumbers:SetText("1\n2")
    
    -- Обновляем текущий файл, чтобы он указывал на новое расположение
    local currentPath = self:GetSelectedFolder()
    self.CurrentFile = currentPath .. "/новый_файл.txt" -- По умолчанию .txt
end

function CodeEditor:OpenFileDialog()
    local frame = vgui.Create("DFrame")
    frame:SetSize(500, 400)
    frame:Center()
    frame:SetTitle("Открыть файл")
    frame:MakePopup()
    
    local fileBrowser = vgui.Create("DListView", frame)
    fileBrowser:Dock(FILL)
    fileBrowser:AddColumn("Файлы")
    
    local files, folders = file.Find(self.FileSystem.CurrentDir .. "/*", "DATA")
    
    -- Add folders
    for _, folder in ipairs(folders) do
        fileBrowser:AddLine("[Папка] " .. folder)
    end
    
    -- Add files
    for _, filename in ipairs(files) do
        fileBrowser:AddLine(filename)
    end
    
    local openBtn = vgui.Create("DButton", frame)
    openBtn:Dock(BOTTOM)
    openBtn:SetText("Открыть")
    openBtn.DoClick = function()
        local selectedLine = fileBrowser:GetSelectedLine()
        if selectedLine then
            local line = fileBrowser:GetLine(selectedLine)
            local filename = line:GetColumnText(1)
            
            if string.StartWith(filename, "[Папка] ") then
                -- Handle folder selection
                self.FileSystem.CurrentDir = self.FileSystem.CurrentDir .. "/" .. string.sub(filename, 9)
                self:RefreshFileList()
                frame:Close()
            else
                self:OpenFile(filename)
                frame:Close()
            end
        end
    end
end

function CodeEditor:SaveFileDialog()
    local frame = vgui.Create("DFrame")
    frame:SetSize(300, 150)
    frame:Center()
    frame:SetTitle("Сохранить файл")
    frame:MakePopup()
    
    local nameEntry = vgui.Create("DTextEntry", frame)
    nameEntry:SetPlaceholderText("Введите имя файла...")
    nameEntry:Dock(TOP)
    nameEntry:DockMargin(5, 5, 5, 5)
    
    local saveBtn = vgui.Create("DButton", frame)
    saveBtn:Dock(BOTTOM)
    saveBtn:SetText("Сохранить")
    saveBtn.DoClick = function()
        local filename = nameEntry:GetText()
        if filename and filename ~= "" then
            if not string.EndsWith(filename, ".txt") then
                filename = filename .. ".txt"
            end
            
            self.CurrentFile = filename
            self:SaveCurrentFile()
            self:RefreshFileList()
            frame:Close()
        end
    end
end

function CodeEditor:OpenEditor()
    if IsValid(self.Frame) then
        self.Frame:Remove()
        self.Frame = nil
        return
    end

    self:CreateMainWindow()
end

hook.Add("Initialize", "InitCodeEditor", function() 
    concommand.Add("glua_editor", function()
        CodeEditor:OpenEditor()
    end)
end)

hook.Add("OnPlayerChat", "OpenEditorCommand", function(ply, text)
    if text == "!editor" and ply == LocalPlayer() then
        CodeEditor:OpenEditor()
        return true
    end
end)

hook.Add("VGUIMousePressed", "CloseCodeEditorMenu", function(panel)
    if IsValid(CodeEditor.CurrentMenu) and panel ~= CodeEditor.CurrentMenu then
        local x, y = gui.MousePos()
        local menuX, menuY = CodeEditor.CurrentMenu:GetPos()
        local menuW, menuH = CodeEditor.CurrentMenu:GetSize()

        if x < menuX or x > menuX + menuW or y < menuY or y > menuY + menuH then
            CodeEditor.CurrentMenu:Remove()
            CodeEditor.CurrentMenu = nil
        end
    end
end)