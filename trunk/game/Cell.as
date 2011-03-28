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
		
		public function firstEntity(filter:Function = null):Entity {
			if (contents == null) {
				return null;
			}
			for each (var prop:Prop in contents) {
				if (prop is Entity) {
					if (filter != null && !filter(prop)) {
						continue;
					}
					return prop as Entity;
				}
			}
			return null;
		}
		
		public function forEachEntity(callWithEntity:Function, filter:Function = null):void {
			for each (var prop:Prop in contents) {
				if (prop is Entity) {
					if (filter != null && !filter(prop)) {
						continue;
					}
					callWithEntity(prop);
				}
			}
		}
		
		public function occupied():Boolean {
			return (contents != null && contents.length > 0);
		}
		
		public function solid():uint {
			if (contents != null) {
				var solid:uint = 0;
				for (var i:int = 0; i < contents.length; i++) {
					solid |= contents[i].solid;
				}
				return solid;
			}
			return 0;
		}
		
	}

}