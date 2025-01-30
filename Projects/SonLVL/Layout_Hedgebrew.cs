using System;
using System.Collections.Generic;

namespace SonicRetro.SonLVL.API.S1D
{
	public class Layout : LayoutFormatSeparate
	{	
		// Internal Read Generic Layout
		private void ReadLayoutInternal(byte[] rawdata, ref ushort[,] layout)
		{
			int width = ByteConverter.ToUInt16(rawdata, 0);
			int height = ByteConverter.ToUInt16(rawdata, 2);
			layout = new ushort[width, height];
			
			for (int row = 0; row < height; row++)
			{
				ushort ptr = ByteConverter.ToUInt16(rawdata, 4 + (row * 2));
				if (ptr != 0)
					for (int col = 0; col < width; col++)
						layout[col, row] = ByteConverter.ToUInt16(rawdata, ptr + (col *2));
			}
		}

		// Read Foreground Override
		public override void ReadFG(byte[] rawdata, LayoutData layout)
		{
			ReadLayoutInternal(rawdata, ref layout.FGLayout);
		}

		// Read Foreground Override
		public override void ReadBG(byte[] rawdata, LayoutData layout)
		{
			ReadLayoutInternal(rawdata, ref layout.BGLayout);
		}

		// Internal Write Generic Layout
		private void WriteLayoutInternal(ushort[,] layout, out byte[] rawdata)
		{
			List<byte> tmp = new List<byte>();
			
			int width = layout.GetLength(0);
			int height = layout.GetLength(1);
			tmp.AddRange(ByteConverter.GetBytes((ushort)(width)));
			tmp.AddRange(ByteConverter.GetBytes((ushort)(height)));
			
			// Layout Pointers
			for (int row = 0; row < height; row++)
			{
				tmp.AddRange(ByteConverter.GetBytes((ushort)(4 + (height * 2) + (row * width * 2))));
			}

			// Layout Data
			for (int row = 0; row < height; row++)
				for (int col = 0; col < width; col++)
					tmp.AddRange(ByteConverter.GetBytes((ushort)(layout[col, row])));

			rawdata = tmp.ToArray();
		}

		// Write Foreground Override
		public override void WriteFG(LayoutData layout, out byte[] rawdata)
		{
			WriteLayoutInternal(layout.FGLayout, out rawdata);
		}

		// Write Background Override
		public override void WriteBG(LayoutData layout, out byte[] rawdata)
		{
			WriteLayoutInternal(layout.BGLayout, out rawdata);
		}

		public override bool IsResizable { get { return true; } }

		public override System.Drawing.Size MaxSize { get { return new System.Drawing.Size(512, 512); } }

		public override System.Drawing.Size DefaultSize { get { return new System.Drawing.Size(256, 32); } }

		public override int MaxBytes { get { return 32768; } }
    }
}
