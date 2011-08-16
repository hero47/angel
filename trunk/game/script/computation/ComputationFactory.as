package angel.game.script.computation {
	import angel.common.Alert;
	import angel.common.Assert;
	import angel.game.script.Script;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class ComputationFactory {
		
		private static const computationNameToClass:Object = {
			"active":ActiveComputation,
			"distance":DistanceComputation,
			"flagValue":FlagValueComputation,
			"health":HealthComputation,
			"int":ConstantComputation
		}
		
		public function ComputationFactory() {
			Assert.fail("Should never be called");
		}
		
		public static function createFromXml(xml:XML, script:Script):IComputation {
			if (xml.attributes().length() < 1) {
				script.addError("computation requires attribute");
				return null;
			}
			
			var attribute:XML = xml.attributes()[0];
			var attributeName:String = attribute.name();
			
			for (var i:int = 0; i < xml.attributes().length(); ++i)
			var computationClass:Class = computationNameToClass[attributeName];
			
			if (computationClass == null) {
				script.addError("unknown computation " + attributeName);
				return null;
			}
			
			return new computationClass(xml.@[attributeName], script);
		}
		
	}

}