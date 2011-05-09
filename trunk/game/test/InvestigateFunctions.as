package angel.game.test {
	import flash.display.Sprite;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class InvestigateFunctions extends Sprite {
		
		private var foo:Vector.<Function> = new Vector.<Function>();
		
		public function InvestigateFunctions() {
			fillFoo();
			for (var j:int = 0; j < foo.length; j++) {
				foo[j]();
			}
		}

		private function fillFoo():void {
			for (var i:int = 0; i < 5; i++) {
				foo.push(function():void { trace(i); } );
			}
		}
		
		/****** 		produces 5-5-5-5-5
		public function InvestigateFunctions() {
			for (var i:int = 0; i < 5; i++) {
				foo.push(function():void { trace(i); } );
			}
			for (var j:int = 0; j < foo.length; j++) {
				foo[j]();
			}
		}
		 */
		
		/******		produces 5-5-5-5-5
		 * public function InvestigateFunctions() {
			fillFoo();
			for (var j:int = 0; j < foo.length; j++) {
				foo[j]();
			}
		}

		private function fillFoo():void {
			for (var i:int = 0; i < 5; i++) {
				foo.push(function():void { trace(i); } );
			}
		}
		 */
		
		/******		produces 0-1-2-3-4
		public function InvestigateFunctions() {
			for (var i:int = 0; i < 5; i++) {
				fillFoo(i);
			}
			for (var j:int = 0; j < foo.length; j++) {
				foo[j]();
			}
		}

		private function fillFoo(i:int):void {
			foo.push(function():void { trace(i); } );
		}
		 */
		
	}

}