﻿// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "ShaderDev/11NormalMap_v2"
{
	Properties 
	{
		_Color ("Main Color", Color) = (1,1,1,1)
		_MainTex("Main Texture", 2D) = "white" {}
		_NormalMap("Normal map", 2D) = "white" {}
		[KeywordEnum(Off,On)] _UseNormal("Use Normal Map?", Float) = 0
	}
	
	Subshader
	{
		//http://docs.unity3d.com/462/Documentation/Manual/SL-SubshaderTags.html
	    // Background : 1000     -        0 - 1499 = Background
        // Geometry   : 2000     -     1500 - 2399 = Geometry
        // AlphaTest  : 2450     -     2400 - 2699 = AlphaTest
        // Transparent: 3000     -     2700 - 3599 = Transparent
        // Overlay    : 4000     -     3600 - 5000 = Overlay
		Tags { "Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent" }
		Pass
		{
			Blend SrcAlpha OneMinusSrcAlpha
			
			CGPROGRAM
			//http://docs.unity3d.com/Manual/SL-ShaderPrograms.html
			#pragma vertex vert
			#pragma fragment frag
			#pragma shader_feature _USENORMAL_OFF _USENORMAL_ON
			#include "CVGLighting.cginc" 
			//http://docs.unity3d.com/ru/current/Manual/SL-ShaderPerformance.html
			//http://docs.unity3d.com/Manual/SL-ShaderPerformance.html
			uniform half4 _Color;
			uniform sampler2D _MainTex;
			uniform float4 _MainTex_ST;
			
			uniform sampler2D _NormalMap;
			uniform float4 _NormalMap_ST;
			
			//https://msdn.microsoft.com/en-us/library/windows/desktop/bb509647%28v=vs.85%29.aspx#VS
			struct vertexInput
			{
				float4 vertex : POSITION;
				float4 normal : NORMAL;
				float4 texcoord : TEXCOORD0;
				#if _USENORMAL_ON
					float4 tangent : TANGENT;
				#endif
			};
			
			struct vertexOutput
			{
				float4 pos : SV_POSITION;
				float4 texcoord : TEXCOORD0;
				float4 normalWorld : TEXCOORD1;
				#if _USENORMAL_ON
					float4 tangentWorld : TEXCOORD2;
					float3 binormalWorld : TEXCOORD3;
					float4 normalTexCoord : TEXCOORD4;
				#endif
			};
			

			
			
			vertexOutput vert(vertexInput v)
			{
				vertexOutput o; UNITY_INITIALIZE_OUTPUT(vertexOutput, o); // d3d11 requires initialization
				o.pos = mul(UNITY_MATRIX_MVP , v.vertex);
				o.texcoord.xy = (v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw);
				o.normalWorld = normalize(mul(v.normal, unity_WorldToObject));
				
				#if _USENORMAL_ON
					// World space T, B, N values
					o.normalTexCoord.xy = (v.texcoord.xy * _NormalMap_ST.xy + _NormalMap_ST.zw);
					o.tangentWorld = normalize(mul(v.tangent,unity_ObjectToWorld));
					o.binormalWorld = normalize(cross(o.normalWorld, o.tangentWorld) * v.tangent.w);
				#endif
				return o;
			}

			half4 frag(vertexOutput i) : COLOR
			{
				#if _USENORMAL_ON
					float3 worldNormalAtPixel = WorldNormalFromNormalMap(_NormalMap, i.normalTexCoord.xy, i.tangentWorld.xyz, i.binormalWorld.xyz, i.normalWorld.xyz);
					return float4(worldNormalAtPixel,1);
					//return tex2D(_MainTex, i.texcoord) * _Color;
				#else
					return float4(i.normalWorld.xyz,1);
				#endif
			}
			ENDCG
		}
	}
}