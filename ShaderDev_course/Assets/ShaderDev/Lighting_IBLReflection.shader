﻿// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "ShaderDev/17Lighting_IBLReflection"
{
	Properties 
	{
		_Color ("Main Color", Color) = (1,1,1,1)
		_MainTex("Main Texture", 2D) = "white" {}
		_NormalMap("Normal map", 2D) = "white" {}
		[KeywordEnum(Off,On)] _UseNormal("Use Normal Map?", Float) = 0
		_Diffuse("Diffuse %", Range(0,1)) = 1
		[KeywordEnum(Off, Vert, Frag)] _Lighting ("Lighting Mode", Float) = 0
		_SpecularMap ("Specular Map", 2D) = "black" {}
		_SpecularFactor("Specular %",Range(0,1)) = 1
		_SpecularPower("Specular Power", Float) = 100
		[Toggle] _AmbientMode ("Ambient Light?", Float) = 0
		_AmbientFactor ("Ambient %", Range(0,1)) = 1
		
		[KeywordEnum(Off, Refl, Refr)] _IBLMode ("IBL Mode", Float) = 0
		_ReflectionFactor("Reflection %",Range(0,1)) = 1
		
		_Cube("Cube Map", Cube) = "" {}
		_Detail("Reflection Detail", Range(1,9)) = 1.0
		_ReflectionExposure("HDR Exposure", float) = 1.0
		
		
	}
	
	Subshader
	{
		//http://docs.unity3d.com/462/Documentation/Manual/SL-SubshaderTags.html
	    // Background : 1000     -        0 - 1499 = Background
        // Geometry   : 2000     -     1500 - 2399 = Geometry
        // AlphaTest  : 2450     -     2400 - 2699 = AlphaTest
        // Transparent: 3000     -     2700 - 3599 = Transparent
        // Overlay    : 4000     -     3600 - 5000 = Overlay
        
		Tags {"Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent" }
		Pass
		{
			Tags {"LightMode" = "ForwardBase"}
			Blend SrcAlpha OneMinusSrcAlpha
			
			CGPROGRAM
			//http://docs.unity3d.com/Manual/SL-ShaderPrograms.html
			#pragma vertex vert
			#pragma fragment frag
			#pragma shader_feature _USENORMAL_OFF _USENORMAL_ON
			#pragma shader_feature _LIGHTING_OFF _LIGHTING_VERT _LIGHTING_FRAG
			#pragma shader_feature _AMBIENTMODE_OFF _AMBIENTMODE_ON
			#pragma shader_feature _IBLMODE_OFF _IBLMODE_REFL _IBLMODE_REFR
			#include "CVGLighting.cginc" 
			//http://docs.unity3d.com/ru/current/Manual/SL-ShaderPerformance.html
			//http://docs.unity3d.com/Manual/SL-ShaderPerformance.html
			uniform half4 _Color;
			uniform sampler2D _MainTex;
			uniform float4 _MainTex_ST;
			
			uniform sampler2D _NormalMap;
			uniform float4 _NormalMap_ST;
			
			uniform float _Diffuse;
			uniform float4 _LightColor0;
			
			uniform sampler2D _SpecularMap;
			uniform float _SpecularFactor;
			uniform float _SpecularPower;
			
			uniform samplerCUBE _Cube;
			float _ReflectionFactor;
			half _Detail;
			float _ReflectionExposure;
			
			
			#if _AMBIENTMODE_ON
				uniform float _AmbientFactor;
			#endif
			
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
				float4 posWorld : TEXCOORD2;
				#if _USENORMAL_ON
					float4 tangentWorld : TEXCOORD3;
					float3 binormalWorld : TEXCOORD4;
					float4 normalTexCoord : TEXCOORD5;
				#endif
				#if _LIGHTING_VERT
					float4 surfaceColor : COLOR0;
				#else
					#if _IBLMODE_REFL
						float4 surfaceColor : COLOR0;
					#endif
				#endif
			};
			
			// function moved to CVGLighting.cginc
			//float3 IBLRefl (samplerCUBE cubeMap, half detail, float3 worldRefl, float exposure, float reflectionFactor)
			//{
			//	float4 cubeMapCol = texCUBElod(cubeMap, float4(worldRefl, detail)).rgba;
			//	return reflectionFactor * cubeMapCol.rgb * (cubeMapCol.a * exposure);
			//
			//}
			
			vertexOutput vert(vertexInput v)
			{
				vertexOutput o;UNITY_INITIALIZE_OUTPUT(vertexOutput, o);
				o.pos = mul(UNITY_MATRIX_MVP , v.vertex);
				o.texcoord.xy = (v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw);
				o.normalWorld = float4(normalize(mul(normalize(v.normal.xyz),(float3x3)unity_WorldToObject)),v.normal.w);
				
				o.posWorld = mul(unity_ObjectToWorld, v.vertex);
				
				#if _USENORMAL_ON
					// World space T, B, N values
					o.normalTexCoord.xy = (v.texcoord.xy * _NormalMap_ST.xy + _NormalMap_ST.zw);
					//o.tangentWorld = normalize(mul(v.tangent,_Object2World));
					o.tangentWorld = (normalize(mul((float3x3)unity_ObjectToWorld, v.tangent.xyz)),v.tangent.w);
					o.binormalWorld = normalize(cross(o.normalWorld, o.tangentWorld) * v.tangent.w); //https://forum.unity3d.com/threads/floating-point-division-by-zero-at-line-warning-in-unity-5-1.332098/
				#endif
				#if _LIGHTING_VERT
					float3 lightDir  = normalize(_WorldSpaceLightPos0.xyz);
					float3 lightColor = _LightColor0.xyz;
					float attenuation = 1;
					float3 diffuseCol =  DiffuseLambert(o.normalWorld, lightDir, lightColor, _Diffuse, attenuation);
					
					float3 specularMap = tex2D(_SpecularMap, o.texcoord.xy); //float4 specularMap = tex2D(_SpecularMap, o.texcoord.xy);
					//o.posWorld = mul(_Object2World, v.vertex);
					float3 worldSpaceViewDir = normalize(_WorldSpaceCameraPos - o.posWorld);
					float3 specularCol = SpecularBlinnPhong(o.normalWorld, lightDir, worldSpaceViewDir, specularMap.rgb , _SpecularFactor, attenuation, _SpecularPower);
					
					float3 mainTexCol = tex2D(_MainTex, o.texcoord.xy);
					
					o.surfaceColor = float4(mainTexCol * _Color * diffuseCol + specularCol,1);
					#if _AMBIENTMODE_ON
						float3 ambientColor = _AmbientFactor * UNITY_LIGHTMODEL_AMBIENT;
						o.surfaceColor = float4(o.surfaceColor.rgb + ambientColor,1);
					#endif
					
					#if _IBLMODE_REFL
						float3 worldRefl = reflect(-worldSpaceViewDir, o.normalWorld.xyz);
						o.surfaceColor.rgb *= IBLRefl (_Cube, _Detail, worldRefl,  _ReflectionExposure, _ReflectionFactor);
					
					#endif
					
				#else
					#if _IBLMODE_REFL
						float3 worldSpaceViewDir = normalize(_WorldSpaceCameraPos - o.posWorld);
						float3 worldRefl = reflect(-worldSpaceViewDir, o.normalWorld.xyz);
						o.surfaceColor.rgb += IBLRefl (_Cube, _Detail, worldRefl,  _ReflectionExposure, _ReflectionFactor);
					
					#endif				
				
				#endif
				return o;
			}

			half4 frag(vertexOutput i) : COLOR
			{
				float4 finalColor = float4(0,0,0,_Color.a);
				
				#if _USENORMAL_ON
					float3 worldNormalAtPixel = WorldNormalFromNormalMap(_NormalMap, i.normalTexCoord.xy, i.tangentWorld.xyz, i.binormalWorld.xyz, i.normalWorld.xyz);
					//return tex2D(_MainTex, i.texcoord) * _Color;
				#else
					float3 worldNormalAtPixel = i.normalWorld.xyz;
				#endif
				
				#if _LIGHTING_FRAG
					float3 lightDir  = normalize(_WorldSpaceLightPos0.xyz);
					float3 lightColor = _LightColor0.xyz;
					float attenuation = 1;
					float3 diffuseCol =  DiffuseLambert(worldNormalAtPixel, lightDir, lightColor, _Diffuse, attenuation);
					
					float4 specularMap = tex2D(_SpecularMap, i.texcoord.xy);
					
					float3 worldSpaceViewDir = normalize(_WorldSpaceCameraPos - i.posWorld);
					float3 specularCol = SpecularBlinnPhong(worldNormalAtPixel, lightDir, worldSpaceViewDir, specularMap.rgb , _SpecularFactor, attenuation, _SpecularPower);
					
					float3 mainTexCol = tex2D(_MainTex, i.texcoord.xy);
					finalColor.rgb += mainTexCol * _Color * diffuseCol + specularCol;
					
					#if _AMBIENTMODE_ON
						float3 ambientColor = _AmbientFactor * UNITY_LIGHTMODEL_AMBIENT;
						finalColor.rgb += ambientColor;
					#endif
					
					#if _IBLMODE_REFL
						float3 worldRefl = reflect(-worldSpaceViewDir, worldNormalAtPixel);
						finalColor.rgb *= IBLRefl (_Cube, _Detail, worldRefl,  _ReflectionExposure, _ReflectionFactor);
					#endif

				#elif _LIGHTING_VERT
					finalColor = i.surfaceColor;
				#else
					#if _IBLMODE_REFL
						float3 worldSpaceViewDir = normalize(_WorldSpaceCameraPos - i.posWorld);
						float3 worldRefl = reflect(-worldSpaceViewDir, worldNormalAtPixel);
						finalColor.rgb += IBLRefl (_Cube, _Detail, worldRefl,  _ReflectionExposure, _ReflectionFactor);
					#endif	

				#endif
				return finalColor;
			}
			ENDCG
		}
	}
}