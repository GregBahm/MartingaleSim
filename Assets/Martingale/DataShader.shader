Shader "Unlit/DataShader"
{
	Properties
	{
		_StrokeThickness("Stroke Thickness", Range(0, 0.05)) = 1
	}
	SubShader
	{
		Pass
		{
			Cull Off

			CGPROGRAM
			#pragma vertex vert
			#pragma geometry geo
			#pragma fragment frag
			#pragma target 5.0 
			
			#include "UnityCG.cginc"

			struct StrokeSegment
			{
				float height : TEXCOORD0;
				float time : TEXCOORD1;
				float unsortedIndex : TEXCOORD2;
				float sortedIndex : TEXCOORD3;
				float sessionHeight : TEXCOORD4;
				float sessionValue : TEXCOORD5;
				float End : TEXCOORD6;
			};

			struct v2g
			{
				float3 StartPosition  : TEXCOORD0;
				float3 EndPosition  : TEXCOORD1;
				float3 Color  : TEXCOORD2;
				bool End : TEXCOORD3; 
			};

			struct g2f
			{
				float4 vertex : SV_POSITION;
				float3 color : COLOR0;
				float lowerHeight : TEXCOORD0;
				float upperHeight : TEXCOORD1;
			};

			float4x4 _Transform;
			float _StrokeThickness;
			float _SortStrength;

			StructuredBuffer<StrokeSegment> _TheBuffer;

			v2g vert(uint meshId : SV_VertexID, uint instanceId : SV_InstanceID)
			{
				StrokeSegment segmentStart = _TheBuffer[instanceId];
				StrokeSegment segmentEnd = _TheBuffer[instanceId - 1];

				float x = lerp(segmentStart.unsortedIndex, segmentStart.sortedIndex, _SortStrength);
				v2g o;
				o.StartPosition = float3(x, segmentStart.height, segmentStart.time);
				o.EndPosition = float3(x, segmentEnd.height, segmentEnd.time);
				o.End = segmentEnd.End;
				float xColor = 1 - segmentStart.sessionHeight;
				float yColor = segmentStart.sessionValue;
				float zColor = .5;
				o.Color = float3(xColor, yColor, zColor);
				o.Color = pow(o.Color, 2);
				if (segmentEnd.End)
				{
					o.StartPosition.yz = 0;
					o.Color = 0;
				}
				return o;
			}

			[maxvertexcount(4)]
			void geo(point v2g p[1], inout TriangleStream<g2f> triStream)
			{
				float3 strokeThickener = float3(_StrokeThickness, 0, 0);

				float3 pointA = p[0].StartPosition;
				float3 pointB = p[0].EndPosition;
				float3 pointC = p[0].EndPosition;
				pointC.y = 0;
				float3 pointD = p[0].StartPosition;
				pointD.y = 0;

				pointA = mul(_Transform, float4(pointA, 1)).xyz;
				pointB = mul(_Transform, float4(pointB, 1)).xyz;
				pointC = mul(_Transform, float4(pointC, 1)).xyz;
				pointD = mul(_Transform, float4(pointD, 1)).xyz;

				g2f o;
				o.color = p[0].Color;
				o.vertex = UnityObjectToClipPos(pointB);
				o.upperHeight = 0;
				o.lowerHeight = p[0].EndPosition.y;
				triStream.Append(o);

				o.vertex = UnityObjectToClipPos(pointA);
				o.lowerHeight = p[0].StartPosition.y;
				triStream.Append(o);

				o.vertex = UnityObjectToClipPos(pointC);
				o.lowerHeight = 0;
				o.upperHeight = p[0].EndPosition.y;
				triStream.Append(o);

				o.vertex = UnityObjectToClipPos(pointD);
				o.upperHeight = p[0].StartPosition.y;
				triStream.Append(o);
			}
			
			fixed4 frag (g2f i) : SV_Target
			{
				float breakEvenStrip = i.lowerHeight > .134 && i.lowerHeight < .135;
				float3 ret = i.color * float3(1, 1, i.lowerHeight);
				ret += ret * pow(1 - i.upperHeight, 50);
				ret += breakEvenStrip;
				//ret = saturate(ret);
				return float4(ret, 1);
			}
			ENDCG
		}
	}
	Fallback "Diffuse"
}
