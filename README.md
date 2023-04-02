# IDexpand
このTweakはMCPE(0.16.2)のアイテムIDを512から4096に拡張します。

This Tweak expands the item ID of MCPE(0.16.2) for iOS from 512 to 4096.
<br>
<br>
<br>
<br>
<br>
### このTweakを使用してアイテム追加する場合、次のようにコードを編集する必要があります。

`static Item** Item$mItems`は`static Item*** Item$mItems`に編集してください。

`Item$registerItems`内の`Item$mItems[tim] = myItemPtr;`は`Item$mItems[1][tim] = myItemPtr;`に編集してください。

`%ctor`内の`Item$mItems = (Item**)(0x1012ae238 + _dyld_get_image_vmaddr_slide(0));`は`Item$mItems = (Item***)(0x1012ae238 + _dyld_get_image_vmaddr_slide(0));`に編集してください。
