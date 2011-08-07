package angel.common {
	import angel.game.combat.MedPack;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class GizmoResource extends InventoryResourceBase {
		
		public static const TAG:String = "gizmo";
		
		[Embed(source='../EmbeddedAssets/default_nonweapon.png')]
		public static const DEFAULT_NONWEAPON_ICON:Class;
		
		private static const typeToClass:Object = { "medpack":MedPack };
		
		public var type:String;
		public var value:int;
		
		public function GizmoResource() {
			super();
		}
		
		override public function prepareTemporaryVersionForUse(id:String, entry:CatalogEntry, errors:MessageCollector):void {
			super.prepareTemporaryVersionForUse(id, entry, errors);
			
			if (entry.xml != null) {
				type = entry.xml.@type;
			}
			if (Util.nullOrEmpty(type)) {
				type = Defaults.GIZMO_TYPE;
			}
			myItemClass = typeToClass[type];
			if (myItemClass == null) {
				MessageCollector.collectOrShowMessage(errors, "Unknown gizmo type " + type);
				myItemClass = MedPack;
				//CONSIDER default type should probably be MacGuffin once we have those
			}
			
			Util.setIntFromXml(this, "value", entry.xml, "value");
			
			entry.xml = null;
			
			iconBitmapData = defaultBitmapData(DEFAULT_NONWEAPON_ICON);
		}
		
	}

}