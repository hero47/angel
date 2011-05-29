package angel.game.action {
	import angel.common.Alert;
	import angel.common.Assert;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class Computation {
		
		private static const computationNameToClass:Object = {
			"distance":DistanceComputation,
			"health":HealthComputation,
			"int":ConstantComputation
		}
		
		public function Computation() {
			Assert.fail("Should never be called");
		}
		
		public static function createFromXml(xml:XML, errorPrefix:String = "Script computation"):IComputation {
			if (xml.attributes().length() != 1) {
				Alert.show(errorPrefix + " requires attribute");
				return null;
			}
			
			var attribute:XML = xml.attributes()[0];
			var attributeName:String = attribute.name();
			var computationClass:Class = computationNameToClass[attributeName];
			
			if (computationClass == null) {
				Alert.show(errorPrefix + " unknown computation " + attributeName);
				return null;
			}
			
			return new computationClass(xml.@[attributeName]);
		}
		
	}

}