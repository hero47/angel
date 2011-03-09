package angel.roomedit {
	import angel.common.Catalog;
	import angel.common.CatalogEntry;
	

	public class CatalogEdit extends Catalog {
		
		public function CatalogEdit() {
			
		}
		
		public function allPropNames():Array {
			var all:Array = new Array();
			for (var foo:String in lookup) {
				var entry:CatalogEntry = lookup[foo];
				if (entry.type == PROP) {
					all.push(foo);
				}
			}
			all.sort();
			return all;
		}
		
	}

}