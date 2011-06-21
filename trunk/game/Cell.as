package angel.game {
	import angel.common.Assert
	import angel.common.Prop;

	// The room the player currently occupies is divided into Cells.  Each cell represents the contents of one
	// square on the map, including any terrain properties.
	public class Cell {
		
		public var contents:Vector.<Prop>;
		
		public function Cell() {
			
		}
		
		public function add(prop:Prop):void {
			if (contents == null) {
				contents = new Vector.<Prop>();
			}
			contents.push(prop);
		}
		
		public function remove(prop:Prop):void {
			Assert.assertTrue(contents != null && contents.indexOf(prop) >= 0, "Removing something that's not there");
			if (contents != null) {
				var i:int = contents.indexOf(prop);
				if (i >= 0) {
					contents.splice(i, 1);
				}
			}
		}
		
		public function firstEntity(filter:Function = null):SimpleEntity {
			return firstEntityOfType(SimpleEntity, filter);
		}
		
		public function firstComplexEntity(filter:Function = null):ComplexEntity {
			return firstEntityOfType(ComplexEntity, filter) as ComplexEntity;
		}
		
		private function firstEntityOfType(type:Class, filter:Function = null): SimpleEntity {
			if (contents == null) {
				return null;
			}
			for each (var prop:Prop in contents) {
				if ((prop is type) && ((filter == null) || (filter(prop)))) {
					return prop as SimpleEntity;
				}
			}
			return null;
		}
		
		public function forEachEntity(callWithEntity:Function, filter:Function = null):void {
			if (contents == null) {
				return;
			}
			var contentsCopy:Vector.<Prop> = contents.concat(); // clone in case callback deletes something
			for each (var prop:Prop in contentsCopy) {
				if ((prop is SimpleEntity) && ((filter == null) || filter(prop))) {
					callWithEntity(prop);
				}
			}
		}
		
		public function occupied():Boolean {
			return (contents != null && contents.length > 0);
		}
		
		// If ignoreInvisible is true, pretend anything invisible doesn't exist.
		public function solidness(ignoreInvisible:Boolean = false):uint {
			if (contents != null) {
				var solid:uint = 0;
				for (var i:int = 0; i < contents.length; i++) {
					if (ignoreInvisible && !contents[i].visible) {
						continue;
					}
					solid |= contents[i].solidness;
				}
				return solid;
			}
			return 0;
		}
		
	}

}