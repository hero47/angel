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
			Assert.assertTrue(contents != null && contents.indexOf(prop) >= 0, "Removing entity that's not there");
			if (contents != null) {
				var i:int = contents.indexOf(prop);
				if (i >= 0) {
					contents.splice(i, 1);
				}
			}
		}
		
		public function occupied():Boolean {
			return (contents != null && contents.length > 0);
		}
		
		public function solid():Boolean {
			if (contents != null) {
				for (var i:int = 0; i < contents.length; i++) {
					if (contents[i].solid) {
						return true;
					}
				}
			}
			return false;
		}
		
	}

}