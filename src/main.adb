with Ada.Text_IO;
with Ada.Command_Line;
with Ada.Float_Text_IO;
with Ada.Integer_Text_IO;

procedure Main is

   package Commands is
      type Command is (Unknown, Show_Help, Show_Result, Create_New_File, Replace_File);
      package IO is new Ada.Text_IO.Enumeration_IO (Command);
   end;

   function Get_Command return Commands.Command is
      use Ada.Command_Line;
   begin
      if Argument (1) = "help" then
         return Commands.Show_Help;
      elsif Argument (1) = "show" then
         return Commands.Show_Result;
      elsif Argument (1) = "create" then
         return Commands.Create_New_File;
      elsif Argument (1) = "replace" then
         return Commands.Replace_File;
      else
         return Commands.Unknown;
      end if;
   end;

   function Get_Command_Help (X : Commands.Command) return String is
   begin
      case X is
         when Commands.Show_Result =>
            return "show    <Scale> <File_Name>";
         when Commands.Create_New_File =>
            return "create  <Scale> <File_Name> <File_Name>";
         when Commands.Replace_File =>
            return "replace <Scale> <File_Name>";
         when others =>
            return "";
      end case;
   end;

   type Float_Array is array (Integer range <>) of Float;
   type Distance_Function is access function (A, B : Float) return Float;
   function Canberra_Part (A, B : Float) return Float is (if A = 0.0 and B = 0.0 then 0.0 else (A - B) / (abs A + abs B));
   function Manhattan_Part (A, B : Float) return Float is (abs (A - B));

   function Calculate_Distance (F : Distance_Function; W, A, B : Float_Array) return Float is
      S : Float := 0.0;
   begin
      for I in W'Range loop
         S := S + W (I) * F (A (I), B (I));
      end loop;
      return S;
   end;



   function Get_Distance (Name : String) return Distance_Function is
   begin
      if Name = "canberra" then
         return Canberra_Part'Access;
      elsif Name = "manhattan" then
            return Manhattan_Part'Access;
      else
         return null;
      end if;
   end;

   procedure Write (Name : String; X : Float_Array) is
      use Ada.Text_IO;
      use Ada.Float_Text_IO;
      F : File_Type;
   begin
      Create (F, Out_File, Name);
      for I in X'Range loop
         Put (F, X (I));
         New_Line (F);
      end loop;
      Close (F);
   end;

   procedure Put (X : Float_Array) is
      use Ada.Float_Text_IO;
   begin
      for I in X'Range loop
         Put (X (I), 3, 3, 0);
      end loop;
   end;

   generic
      Dimension_Count : Natural;
   package Generic_Assets is
      subtype Dimension is Integer range 1 .. Dimension_Count;
      subtype Weight is Float_Array (Dimension);
      subtype Point is Float_Array (Dimension);
      type Asset is record
         P : Point;
      end record;
      type Asset_Array is array (Integer range <>) of Asset;
      procedure Read (Name : String; D : Dimension; X : out Asset_Array; Last : out Integer);
      procedure Calculate_Distance (F : Distance_Function; W : Float_Array;  S : Float_Array; X : Asset_Array; D : out Float_Array);
      procedure Put (X : Asset_Array; D : Float_Array);
   end;

   package body Generic_Assets is
      procedure Read (Name : String; D : Dimension; X : out Asset_Array; Last : out Integer) is
         use Ada.Text_IO;
         use Ada.Float_Text_IO;
         F : File_Type;
      begin
         Open (F, In_File, Name);
         Last := X'First - 1;
         loop
            exit when End_Of_File (F);
            Last := Last + 1;
            Get (F, X (Last).P (D));
            exit when Last = X'Last;
         end loop;
         Close (F);
      end;
      procedure Calculate_Distance (F : Distance_Function; W : Float_Array;  S : Float_Array; X : Asset_Array; D : out Float_Array) is
      begin
         for I in X'Range loop
            D (I) := Calculate_Distance (F, W, X (I).P, S);
         end loop;
      end;
      procedure Put (X : Asset_Array; D : Float_Array) is
         use Ada.Text_IO;
         use Ada.Float_Text_IO;
         use Ada.Integer_Text_IO;
      begin
         for I in X'Range loop
            Put (I, 4);
            Put (X (I).P);
            Put ("|");
            Put (D (I), 3, 3, 0);
            New_Line;
         end loop;
      end;
   end;

   procedure Help is
   begin
      for I in Commands.Command loop
         Ada.Integer_Text_IO.Put (I'Enum_Rep, 3);
         Ada.Text_IO.Put (" ");
         Commands.IO.Put (I, Commands.Command'Width + 1);
         Ada.Text_IO.Put (Get_Command_Help (I));
         Ada.Text_IO.New_Line;
      end loop;
   end;

   procedure Run is
      use Ada.Command_Line;
      Asset_Count : constant Natural := Natural'Value (Argument (2));
      Distance_Fun : constant Distance_Function := Get_Distance (Argument (3));
      Dimension_Count : constant Natural := Natural'Value (Argument (4));
      package Assets is new Generic_Assets (Dimension_Count);
      X : Assets.Asset_Array (1 .. Asset_Count);
      D : Float_Array (X'Range);
      W : Assets.Weight := (others => 1.0);
      Last : Natural;
   begin
      for I in Assets.Dimension'Range loop
         Assets.Read (Argument (I + 4), I, X, Last);
         W (I) := Float'Value (Argument (I + 4 + Dimension_Count));
      end loop;
      Assets.Calculate_Distance (Distance_Fun, W, X (1).P, X (X'First .. Last), D);
      Assets.Put (X (X'First .. Last), D (X'First .. Last));
   end;

begin

   case Get_Command is
      when Commands.Show_Result =>
         Run;
      when others =>
         Ada.Text_IO.Put_Line ("Unsupported command");
         Help;
   end case;


   null;
end;

