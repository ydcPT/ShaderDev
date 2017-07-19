Shader "ShaderDev/BareBone" 
{
	Properties
	{
		_Color("Main color", color) = (1, 1, 1, 1)
	}

	Subshader
	{
		Pass
		{
			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag

			uniform half4 _Color;

			struct vertexInput 
			{
				float4 vertex : POSITION;	
			};

			struct vertexOutput
			{
				float4 pos : SV_POSITION;
			};

			vertexOutput vert(vertexInput v)
			{
				vertexOutput o;

				o.pos = mul(UNITY_MATRIX_MVP, v.vertex);

				return o;
			}

			half4 frag(vertexOutput i) : COLOR
			{
				return _Color;
			}

			ENDCG
		}
	}
}